# ExDocEPUB

Create documentation for Elixir projects in the EPUB format.

## Installation

Add `ex_doc_epub` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:earmark, "~> 0.1.17", only: :docs}
    {:ex_doc_epub, github: "milmazz/ex_doc_epub", only: :docs}
  ]
end
```

`ExDocEPUB` rely on [ExDoc](https://github.com/elixir-lang/ex_doc) to do the
hard work!

Build your dependencies:

```bash
MIX_ENV=docs mix do deps.get, compile
```

Build your docs:

```bash
MIX_ENV=docs mix docs.epub
```
