defmodule ExDocEPUB.Mixfile do
  use Mix.Project

  @version "0.0.3"

  def project do
    [app: :ex_doc_epub,
     version: @version,
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,

     # Hex.pm
     description: description,
     package: package(),

     # Docs
     name: "ExDocEPUB",
     docs: docs()]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:earmark, "~> 0.1.17", optional: true},
      {:ex_doc, "~> 0.9"}]
  end

  defp description do
    """
    Create documentation for Elixir projects in EPUB format
    """
  end

  defp package do
    [maintainers: ["Milton Mazzarri"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/milmazz/ex_doc_epub",
              "Docs" => "http://hexdocs.pm/ex_doc_epub/#{@version}"}]
  end

  defp docs do
    [readme: "readme.md",
     source_ref: "v#{@version}", main: "ExDocEPUB.Formatter.EPUB",
     source_url: "https://github.com/milmazz/ex_doc_epub"]
  end
end
