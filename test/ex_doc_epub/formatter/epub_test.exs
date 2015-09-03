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

  test "Run generates an EPUB file" do
    generate_docs(doc_config)
    assert File.exists?("#{doc_config[:output]}/#{doc_config[:project]}-v#{doc_config[:version]}.epub") == true
  end
end
