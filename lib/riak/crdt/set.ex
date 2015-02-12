defmodule Riak.CRDT.Set do
  @moduledoc """
  Encapsulates riakc_set using elixir Set functions as interface.
  It accepts only binary as items.
  """
  require Record

  @doc """
  Create an empty set
  """
  def new, do: :riakc_set.new

  @doc """
  Get original value as an `ordset`
  """
  def value(set) when Record.is_record(set, :set) do
    :riakc_set.value(set)
  end

  @doc """
  Checks if `set` contains `value`.
  """
  def member?(set, value) when Record.is_record(set, :set) and is_binary(value) do
    :riakc_set.is_element(value, set)
  end

  @doc """
  Insert `value` on `set`
  """
  def put(set, value) when Record.is_record(set, :set) and is_binary(value) do
    :riakc_set.add_element(value, set)
  end

  @doc """
  Delete `value` on `set`
  """
  def delete(set, value) when Record.is_record(set, :set) and is_binary(value) do
    :riakc_set.del_element(value, set)
  end

  @doc """
  Returns the number of elements in `set`
  """
  def size(set) when Record.is_record(set, :set) do
    :riakc_set.size(set)
  end
end
