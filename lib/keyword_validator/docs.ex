defmodule KeywordValidator.Docs do
  @moduledoc false

  @type docs :: binary()

  alias KeywordValidator.Schema

  ################################
  # Public API
  ################################

  @doc false
  @spec build(struct()) :: docs()
  def build(%Schema{schema: schema}) do
    do_build(schema, [])
  end

  ################################
  # Private API
  ################################

  defp do_build([], docs), do: IO.iodata_to_binary(docs)

  defp do_build([{key, value} | schema], docs) do
    docs =
      if value.doc do
        docs ++ [do_build_key(key), " - ", do_build_doc(value), "\n"]
      else
        docs
      end

    do_build(schema, docs)
  end

  defp do_build_key(key) do
    ["* ", "`", inspect(key), "`"]
  end

  defp do_build_doc(value) do
    [maybe_required(value), value.doc, maybe_default(value)]
  end

  defp maybe_required(value) do
    if value.required do
      [" ", "Required.", " "]
    else
      []
    end
  end

  defp maybe_default(value) do
    if value.default != nil do
      [" ", "Defaults to ", "`", inspect(value.default), "`", ".", " "]
    else
      []
    end
  end
end
