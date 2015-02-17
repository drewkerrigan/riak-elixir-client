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

  def error(code, args \\ []) do
    {:error, code: code, message: t!("en", code, args)}
  end
end