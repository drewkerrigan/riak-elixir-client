defmodule Riak.CRDT do
  @moduledoc """
  Common CRDT module
  """
  require Record

  Enum.each [:set, :map, :counter, :register, :flag, :hll], fn t ->
    def type(value) when Record.is_record(value, unquote(t)), do: unquote(t)
  end
end
