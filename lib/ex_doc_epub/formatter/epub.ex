defmodule ExDocEPUB.Formatter.EPUB do
  @moduledoc """
  Provide EPUB documentation
  """

  alias ExDoc.Formatter.HTML
  alias ExDocEPUB.Formatter.EPUB.Templates

  @doc """
  Generate EPUB documentation for the given modules
  """
  @spec run(list, %ExDoc.Config{}) :: String.t
  def run(module_nodes, config) when is_map(config) do
    output = Path.expand(config.output)
    File.rm_rf!(output)
    :ok = File.mkdir_p("#{output}/OEBPS/modules")

    generate_assets(output, config)

    all = HTML.Autolink.all(module_nodes)
    modules = HTML.filter_list(:modules, all)
    exceptions = HTML.filter_list(:exceptions, all)
    protocols = HTML.filter_list(:protocols, all)

    has_readme = config.readme && generate_readme(output, config, module_nodes)

    uuid = "urn:uuid:#{uuid4()}"
    datetime = format_datetime()
    generate_content(output, config, modules, exceptions, protocols, uuid, datetime, has_readme)
    generate_toc(output, config, modules, exceptions, protocols, uuid, has_readme)
    generate_nav(output, config, modules, exceptions, protocols, has_readme)
    generate_title(output, config)
    generate_list(output, config, modules)
    generate_list(output, config, exceptions)
    generate_list(output, config, protocols)

    {:ok, epub_file} = generate_epub(output, config)
    delete_extras(output)

    epub_file
  end

  # Helper to generate an UUID v4. This version uses pseudo-random bytes generated by
  # the `crypto` module.
  defp uuid4 do
    <<u0::48, _::4, u1::12, _::2, u2::62>> = :crypto.rand_bytes(16)
    bin = <<u0::48, 4::4, u1::12, 2::2, u2::62>>
    <<u0::32, u1::16, u2::16, u3::16, u4::48>> = bin

    Enum.map_join([<<u0::32>>, <<u1::16>>, <<u2::16>>, <<u3::16>>, <<u4::48>>], <<45>>, &(binary_to_hex_list(&1)))
    |> IO.iodata_to_binary
    |> String.downcase
  end

  defp binary_to_hex_list(binary) do
    :binary.bin_to_list(binary)
    |> Enum.reduce('', &(&2 ++ Integer.to_char_list(&1, 16)))
  end

  defp templates_path(other) do
    Path.expand("epub/templates/#{other}", __DIR__)
  end

  defp assets do
   [
     { templates_path("css/*.css"), "OEBPS/css" },
     { templates_path("assets/*.xml"), "META-INF" },
     { templates_path("assets/mimetype"), "." }
   ]
  end

  defp generate_assets(output, _config) do
    Enum.each assets, fn({pattern, dir}) ->
      output = "#{output}/#{dir}"

      unless File.exists?(output) do
        File.mkdir_p output
      end

      Enum.map Path.wildcard(pattern), fn(file) ->
        base = Path.basename(file)
        File.copy(file, "#{output}/#{base}")
      end
    end
  end

  defp generate_readme(output, config, module_nodes) do
    readme_path = Path.expand(config.readme)
    write_readme(output, config, module_nodes, File.read(readme_path))
  end

  defp write_readme(output, config, module_nodes, {:ok, content}) do
    content = HTML.Autolink.project_doc(content, module_nodes)
    readme_html = Templates.readme_template(config, content)
    :ok = File.write("#{output}/OEBPS/modules/README.html", readme_html)
    true
  end

  defp write_readme(_, _, _, _) do
    false
  end

  defp generate_content(output, config, modules, exceptions, protocols, uuid, datetime, has_readme) do
    content = Templates.content_template(config, modules ++ exceptions ++ protocols, uuid, datetime, has_readme)
    File.write("#{output}/OEBPS/content.opf", content)
  end

  defp generate_toc(output, config, modules, exceptions, protocols, uuid, has_readme) do
    content = Templates.toc_template(config, modules ++ exceptions ++ protocols, uuid, has_readme)
    File.write("#{output}/OEBPS/toc.ncx", content)
  end

  defp generate_nav(output, config, modules, exceptions, protocols, has_readme) do
    content = Templates.nav_template(config, modules ++ exceptions ++ protocols, has_readme)
    File.write("#{output}/OEBPS/nav.html", content)
  end

  defp generate_title(output, config) do
    content = Templates.title_template(config)
    File.write("#{output}/OEBPS/title.html", content)
  end

  defp generate_list(output, config, nodes) do
    nodes
    |> Enum.map(&Task.async(fn -> generate_module_page(output, config, &1) end))
    |> Enum.map(&Task.await/1)
  end

  defp generate_module_page(output, config, node) do
    content = Templates.module_page(config, node)
    File.write("#{output}/OEBPS/modules/#{node.id}.html", content)
  end

  defp generate_epub(output, config) do
    output = Path.expand(output)
    target_path = "#{output}/#{config.project}-v#{config.version}.epub" |> String.to_char_list
    {:ok, zip_path} = :zip.create(target_path,
                  files_to_add(output),
                  uncompress: ['mimetype'])
    {:ok, zip_path}
  end

  defp files_to_add(path) do
    File.cd! path, fn ->
      meta = Path.wildcard("META-INF/*")
      oebps = Path.wildcard("OEBPS/**/*")

      Enum.reduce meta ++ oebps ++ ["mimetype"], [], fn(f, acc) ->
        case File.read(f) do
          {:ok, bin} ->
            [{f |> String.to_char_list, bin}|acc]
          {:error, _} ->
            acc
        end
      end
    end
  end

  defp delete_extras(output) do
    for target <- ["META-INF", "mimetype", "OEBPS"] do
      File.rm_rf! "#{output}/#{target}"
    end
    :ok
  end

  # Helper to format Erlang datetime tuple
  defp format_datetime do
    {{year, month, day}, {hour, min, sec}} = :calendar.universal_time()
    date = Enum.map_join([{year, 4}, {month, 2}, {day, 2}], "-", fn({k, v}) -> zero_pad(k, v) end)
    time = Enum.map_join([{hour, 2}, {min, 2}, {sec, 2}], ":", fn({k, v}) -> zero_pad(k, v) end)
    "#{date}T#{time}Z"
  end

  defp zero_pad(val, count) do
    num = Integer.to_string(val)
    :binary.copy("0", count - byte_size(num)) <> num
  end
end
