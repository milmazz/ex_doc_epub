defmodule ExDocEPUB.Formatter.EPUB.Templates do
  @moduledoc """
  Handle all template interfaces for the EPUB formatter.
  """

  require EEx

  @content_template_doc """
  Creates the [Package Document Definition](http://www.idpf.org/epub/30/spec/epub30-publications.html#sec-package-def),
  this definition encapsulates the publication metadata and the resource
  information that constitute the EPUB publication. This definition also
  includes the default reading order.
  """
  @detail_template_doc """
  Returns the details of an individual *function*, *macro* or *callback*.  This
  function is required used by `module_template/6`.
  """
  @module_template_doc """
  Creates a chapter which contains all the details about an individual module,
  this chapter can include the following sections: *functions*, *macros*,
  *types*, *callbacks*.
  """
  @nav_template_doc """
  Creates the table of contents. This template follows the
  [EPUB Navigation Document Definition](http://www.idpf.org/epub/30/spec/epub30-contentdocs.html#sec-xhtml-nav).
  """
  @readme_template_doc """
  Creates a new chapter when the user provides a `README` file.
  """
  @summary_template_doc """
  Creates a summary of the *functions* and *macros* available for an individual
  module, this function is required by `module_template/6`.
  """
  @title_template_doc """
  Creates the cover page for the EPUB document.
  """
  @toc_template_doc """
  Creates an *Navigation Center eXtended* document (as defined in OPF 2.0.1),
  this is for compatibility purposes with EPUB 2 Reading Systems.  EPUB 3
  Reading Systems must ignore the NCX in favor of the [EPUB Navigation Document](http://www.idpf.org/epub/30/spec/epub30-contentdocs.html#sec-xhtml-nav).
  """
  @type_detail_template_doc """
  Returns all the details of an individual *type*. This function is required by
  `module_template/6`.
  """

  @doc """
  Generate content from the module template for a given `node`
  """
  def module_page(config, node) do
    types       = node.typespecs
    functions   = Enum.filter node.docs, & &1.type in [:def]
    macros      = Enum.filter node.docs, & &1.type in [:defmacro]
    callbacks   = Enum.filter node.docs, & &1.type in [:defcallback, :defmacrocallback]
    module_template(config, node, types, functions, macros, callbacks)
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

  # Keep only valid characters for an XHTML ID element
  defp valid_id(binary) do
    String.replace(binary, ~r/[^A-Za-z0-9:_.-]/, "")
  end

  templates = [
    content_template: [:config, :nodes, :uuid, :datetime, :has_readme],
    detail_template: [:node, :_module],
    module_template: [:config, :module, :types, :functions, :macros, :callbacks],
    nav_template: [:config, :nodes, :has_readme],
    readme_template: [:config, :content],
    summary_template: [:node],
    title_template: [:config],
    toc_template: [:config, :nodes, :uuid, :has_readme],
    type_detail_template: [:node]
  ]

  template_docs = %{
    content_template: @content_template_doc,
    detail_template: @detail_template_doc,
    module_template: @module_template_doc,
    nav_template: @nav_template_doc,
    readme_template: @readme_template_doc,
    summary_template: @summary_template_doc,
    title_template: @title_template_doc,
    toc_template: @toc_template_doc,
    type_detail_template: @type_detail_template_doc
  }

  Enum.each templates, fn({ name, args }) ->
    filename = Path.expand("templates/#{name}.eex", __DIR__)
    @doc Map.get(template_docs, name)
    EEx.function_from_file :def, name, filename, args
  end
end
