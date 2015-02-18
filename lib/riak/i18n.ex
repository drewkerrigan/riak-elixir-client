defmodule Riak.I18n do
  use Linguist.Vocabulary

  locale "en", [
    error: [
      index: [ 
        unsupported: "Secondary indexes are not supported on bitcask storage backend.",
        default: "Unknown secondary index error: %{reason}."
      ]
    ]
  ]

  @doc """
  Look up the human readable error message and return a tuple with the format:
  {:error, [{:code, "error.[module].[specific error]"}, {:message, "human readable message"}]}
  """
  def error(code, args \\ []) do
    {:error, code: code, message: t!("en", code, args)}
  end
end