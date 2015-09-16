defmodule ExDocEPUB.Mixfile do
  use Mix.Project

  @version "0.0.2"

  def project do
    [app: :ex_doc_epub,
     version: @version,
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,

     # Hex.pm
     description: description,
     package: package,

     # Docs
     name: "ExDocEPUB",
     docs: [readme: "README.md",
            source_ref: "v#{@version}", main: "ExDocEPUB.Formatter.EPUB",
            source_url: "https://github.com/milmazz/ex_doc_epub"]]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
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
    [contributors: ["Milton Mazzarri"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/milmazz/ex_doc_epub",
              "Docs" => "http://hexdocs.pm/ex_doc_epub/#{@version}"}]
  end
end
