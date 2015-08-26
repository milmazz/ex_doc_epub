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

    generate_mimetype(output)
    generate_container(output)
    generate_content(output, config, all)
    generate_toc(output, config, all)
    generate_title(output, config)
    generate_list(output, config, modules)
    generate_list(output, config, exceptions)
    generate_list(output, config, protocols)

    #generate_epub(output)
    #File.rm_rf!(output)
  end

  defp templates_path(other) do
    Path.expand("epub/templates/#{other}", __DIR__)
  end

  defp assets do
   [{ templates_path("css/*.css"), "OEBPS/css" }]
  end

  defp generate_assets(output, _config) do
    Enum.each assets, fn({pattern, dir}) ->
      output = "#{output}/#{dir}"
      File.mkdir_p output

      Enum.map Path.wildcard(pattern), fn(file) ->
        base = Path.basename(file)
        File.copy(file, "#{output}/#{base}")
      end
    end
  end

  defp generate_mimetype(output) do
    content = "application/epub+zip"
    File.write("#{output}/mimetype", content)
  end

  defp generate_container(output) do
    content = Templates.container_template()
    File.mkdir_p("#{output}/META-INF")
    File.write("#{output}/META-INF/container.xml", content)
  end

  defp generate_content(output, config, all) do
    content = Templates.content_template(config, all)
    File.write("#{output}/OEBPS/content.opf", content)
  end

  defp generate_toc(output, config, all) do
    content = Templates.toc_template(config, all)
    File.write("#{output}/OEBPS/toc.ncx", content)
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

  #defp generate_epub(output) do
    #zip -0Xq book.epub mimetype
    #zip -Xr9Dq book.epub *
    #project = "elixir.epub"
    #{:ok, _} = :zip.create(String.to_char_list(project),
    #             files_to_add(output),
    #             uncompress: ['mimetype'])
    #:ok
  #end
end
