defmodule ExDocEPUB.Formatter.EPUBTest do
  use ExUnit.Case, async: false

  alias ExDocEPUB.Formatter.EPUB

  setup_all do
    {:ok, _} = File.copy("test/fixtures/README.md", "test/tmp/README.md")

    :ok
  end

  setup do
    {:ok, _} = File.rm_rf(output_dir)
    :ok = File.mkdir(output_dir)
    {:ok, []} = File.ls(output_dir)

    :ok
  end

  defp output_dir do
    Path.expand("../../tmp/doc", __DIR__)
  end

  defp beam_dir do
    Path.expand("../../tmp/ebin", __DIR__)
  end

  defp doc_config do
    [
      project: "Elixir",
      version: "1.0.1",
      formatter: "epub",
      output: "test/tmp/doc",
      source_root: beam_dir,
      source_beam: beam_dir,
      readme: "test/tmp/README.md",
    ]
  end

  defp doc_config(config) do
    Keyword.merge(doc_config, config)
  end

  defp build_config(options) do
    preconfig = %ExDoc.Config{
      project: options[:project],
      version: options[:version],
      main: options[:main],
      homepage_url: options[:homepage_url],
      source_root: options[:source_root] || File.cwd!,
    }
    struct(preconfig, options)
  end

  defp generate_docs(options) do
    config = build_config(options)
    ExDoc.Retriever.docs_from_dir(options[:source_beam], config)
    |> EPUB.run(config)
  end

  defp generate_docs_and_unzip(options) do
    generate_docs(options)
    unzip_dir = "#{doc_config[:output]}" |> String.to_char_list
    "#{doc_config[:output]}/#{doc_config[:project]}-v#{doc_config[:version]}.epub"
    |> String.to_char_list
    |> :zip.unzip([cwd: unzip_dir])
  end

  test "run generates an EPUB file in the default directory" do
    generate_docs(doc_config)
    assert File.regular?("#{output_dir}/#{doc_config[:project]}-v#{doc_config[:version]}.epub") == true
  end

  test "run generates an EPUB file in specified output directory" do
    config = doc_config([output: "#{output_dir}/another_dir", main: "RandomError"])
    generate_docs(config)

    assert File.regular?("#{output_dir}/another_dir/#{doc_config[:project]}-v#{doc_config[:version]}.epub") == true
  end

  test "run generates an EPUB file with a standardized structure" do
    generate_docs_and_unzip(doc_config)

    root_dir = "#{output_dir}"
    meta_dir = "#{root_dir}/META-INF"
    oebps_dir = "#{root_dir}/OEBPS"
    module_dir = "#{oebps_dir}/modules"
    css_dir = "#{oebps_dir}/css"

    assert File.regular?("#{root_dir}/mimetype")
    assert File.regular?("#{meta_dir}/container.xml")
    assert File.regular?("#{meta_dir}/com.apple.ibooks.display-options.xml")
    assert File.regular?("#{css_dir}/stylesheet.css")
    assert File.regular?("#{oebps_dir}/content.opf")
    assert File.regular?("#{oebps_dir}/toc.ncx")
    assert File.regular?("#{oebps_dir}/nav.html")
    assert File.regular?("#{oebps_dir}/title.html")
    assert File.regular?("#{module_dir}/README.html")
    assert File.regular?("#{module_dir}/CompiledWithDocs.html")
    assert File.regular?("#{module_dir}/CompiledWithDocs.Nested.html")
  end

  test "check headers for module pages" do
    generate_docs_and_unzip doc_config([main: "RandomError", ])

    content = File.read!("#{output_dir}/OEBPS/modules/RandomError.html")

    assert content =~ ~r{<html.*xmlns:epub="http://www.idpf.org/2007/ops">}ms
    assert content =~ ~r{<meta charset="utf-8" />}ms
    assert content =~ ~r{<meta name="generator" content="ExDoc" />}
    assert content =~ ~r{<title>RandomError - Elixir v1.0.1</title>}
  end

  test "run generates all listing files" do
    generate_docs_and_unzip(doc_config)

    content = File.read!("#{output_dir}/OEBPS/content.opf")

    assert content =~ ~r{.*"CompiledWithDocs\".*}ms
    assert content =~ ~r{.*"CompiledWithDocs.Nested\".*}ms
    assert content =~ ~r{.*"UndefParent\.Nested\".*}ms
    assert content =~ ~r{.*"CustomBehaviourOne\".*}ms
    assert content =~ ~r{.*"CustomBehaviourTwo\".*}ms
    refute content =~ ~r{UndefParent\.Undocumented}ms
    assert content =~ ~r{.*"RandomError\".*}ms
    assert content =~ ~r{.*"CustomProtocol\".*}ms
  end

  test "run generates the readme file" do
    config = doc_config([main: "README", ])
    generate_docs_and_unzip(config)

    content = File.read!("#{output_dir}/OEBPS/modules/README.html")

    assert content =~ ~r{<title>README [^<]*</title>}
    assert content =~ ~r{<a href="RandomError.html"><code class="inline">RandomError</code>}
    assert content =~ ~r{<a href="CustomBehaviourImpl.html#hello/1"><code class="inline">CustomBehaviourImpl.hello/1</code>}
    assert content =~ ~r{<a href="TypesAndSpecs.Sub.html"><code class="inline">TypesAndSpecs.Sub</code></a>}

    content = File.read!("#{output_dir}/OEBPS/toc.ncx")
    assert content =~ ~r{<text>README</text>}

    content = File.read!("#{output_dir}/OEBPS/nav.html")
    assert content =~ ~r{<li><a href="modules/README.html">README</a></li>}
  end

  test "run should not generate the readme file" do
    generate_docs_and_unzip(doc_config([readme: nil]))

    refute File.regular?("#{output_dir}/OEBPS/modules/README.html")

    content = File.read!("#{output_dir}/OEBPS/content.opf")
    refute content =~ ~r{<title>README [^<]*</title>}

    content = File.read!("#{output_dir}/OEBPS/toc.ncx")
    refute content =~ ~r{<text>README</text>}

    content = File.read!("#{output_dir}/OEBPS/nav.html")
    refute content =~ ~r{<li><a href="modules/README.html">README</a></li>}
  end
end
