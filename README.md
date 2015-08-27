# ExDocEPUB

Create documentation for Elixir projects in the EPUB format.

## Installation

Add `ex_doc_epub` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_doc_epub, github: "milmazz/ex_doc_epub", only: :docs}
  ]
end
```

Build your dependencies:

```bash
MIX_ENV=docs mix do deps.get, compile
```

Build your docs:

```bash
MIX_ENV=docs mix docs.epub
```
