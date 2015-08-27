# ExDocEPUB

Create documentation for Elixir projects in the EPUB format.

## Installation

Add `ex_doc_epub` to your list of dependencies in `mix.exs`:

    def deps do
      [
        {:ex_doc_epub, github: "milmazz/ex_doc_epub", only: :docs}
      ]
    end

Build your dependencies:

    MIX_ENV=docs mix do deps.get, compile

Build your docs:

    MIX_ENV=docs mix docs.epub
