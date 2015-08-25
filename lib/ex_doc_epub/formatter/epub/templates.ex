defmodule ExDocEPUB.Formatter.EPUB.Templates do
  @moduledoc """
  Handle all template interfaces for the EPUB formatter.
  """

  require EEx

  @doc """
  Generate content from the module template for a given `node`
  """
  def module_page(node, config) do
    #types       = node.typespecs
    functions   = Enum.filter node.docs, & &1.type in [:def]
    macros      = Enum.filter node.docs, & &1.type in [:defmacro]
    callbacks   = Enum.filter node.docs, & &1.type in [:defcallback, :defmacrocallback]
    #module_template(config, node, types, functions, macros, callbacks)
    module_template(config, node, functions, macros, callbacks)
  end

  # Get the full specs from a function, already in HTML form.
  defp get_specs(%ExDoc.FunctionNode{specs: specs}) when is_list(specs) do
    presence specs
  end

  defp get_specs(_node), do: nil

  # Convert markdown to HTML.
  defp to_html(nil), do: nil
  defp to_html(bin) when is_binary(bin), do: ExDoc.Markdown.to_html(bin)

  # Get the pretty name of a function node
  defp pretty_type(%ExDoc.FunctionNode{type: t}) do
    case t do
      :def              -> "function"
      :defmacro         -> "macro"
      :defcallback      -> "callback"
      :defmacrocallback -> "macro callback"
      :type             -> "type"
    end
  end

  # Generate a link id
  defp link_id(node), do: link_id(node.id, node.type)
  defp link_id(id, type) do
    case type do
      :defmacrocallback -> "c:#{id}"
      :defcallback      -> "c:#{id}"
      :type             -> "t:#{id}"
      _                 -> "#{id}"
    end
  end

  # Get the first paragraph of the documentation of a node, if any.
  defp synopsis(nil), do: nil
  defp synopsis(doc) do
    String.split(doc, ~r/\n\s*\n/) |> hd |> String.strip() |> String.rstrip(?.)
  end

  defp presence([]),    do: nil
  defp presence(other), do: other

  defp h(binary) do
    escape_map = [{"&", "&amp;"}, {"<", "&lt;"}, {">", "&gt;"}, {"\"", "&quot;"}]
    Enum.reduce escape_map, binary, fn({pattern, escape}, acc) ->
      String.replace(acc, pattern, escape)
    end
  end

  templates = [
    detail_template: [:node, :_module],
    #module_template: [:config, :module, :types, :functions, :macros, :callbacks],
    module_template: [:config, :module, :functions, :macros, :callbacks],
    #overview_entry_template: [:node],
    #overview_template: [:config, :modules, :exceptions, :protocols, :has_readme],
    #readme_template: [:config, :modules, :exceptions, :protocols, :content],
    summary_template: [:node],
    type_detail_template: [:node, :_module],
    container_template: [],
    mimetype_template: [],
    content_template: [],
    toc_template: [],
    title_template: [:config]
  ]

  Enum.each templates, fn({ name, args }) ->
    filename = Path.expand("templates/#{name}.eex", __DIR__)
    EEx.function_from_file :def, name, filename, args
  end
end
