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
    :ok = File.mkdir_p("#{output}/OEBPS")

    generate_assets(output, config)

    all = HTML.Autolink.all(module_nodes)
    modules = HTML.filter_list(:modules, all)
    exceptions = HTML.filter_list(:exceptions, all)
    protocols = HTML.filter_list(:protocols, all)

    generate_content(output, config, modules, exceptions, protocols)
    generate_toc(output, config, modules, exceptions, protocols)
    generate_nav(output, config, modules, exceptions, protocols)
    generate_title(output, config)
    generate_list(output, config, modules)
    generate_list(output, config, exceptions)
    generate_list(output, config, protocols)

    {:ok, epub_file} = generate_epub(output, config)
    delete_extras(output)

    epub_file
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

  defp generate_content(output, config, modules, exceptions, protocols) do
    content = Templates.content_template(config, modules ++ exceptions ++ protocols)
    File.write("#{output}/OEBPS/content.opf", content)
  end

  defp generate_toc(output, config, modules, exceptions, protocols) do
    content = Templates.toc_template(config, modules ++ exceptions ++ protocols)
    File.write("#{output}/OEBPS/toc.ncx", content)
  end

  defp generate_nav(output, config, modules, exceptions, protocols) do
    content = Templates.nav_template(config, modules ++ exceptions ++ protocols)
    File.write("#{output}/OEBPS/nav.html", content)
  end

  defp generate_title(output, config) do
    content = Templates.title_template(config)
    File.write("#{output}/OEBPS/title.html", content)
  end

  defp generate_list(output, config, nodes) do
    File.mkdir_p("#{output}/OEBPS/modules")
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
end
