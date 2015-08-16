defmodule ExDocEPUB.Formatter.EPUB do
  @moduledoc """
  Provide EPUB documentation
  """

  defp templates_path(other) do
    Path.expand("epub/templates/#{other}", __DIR__)
  end
end
