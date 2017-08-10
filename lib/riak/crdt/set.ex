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
  def new(context), do: :riakc_set.new(context)
  def new(value, context) when is_list(value), do: :riakc_set.new(value, context)

  @doc """
  Get original value as an `ordset`
  """
  def value(set) when Record.is_record(set, :set) do
    :riakc_set.value(set)
  end
  def value(nil), do: {:error, :nil_object}
  def value({:error, term}), do: {:error, term}

  @doc """
  Checks if `set` contains `value`.
  """
  def member?(set, value) when Record.is_record(set, :set) and is_binary(value) do
    :riakc_set.is_element(value, set)
  end
  def member?(nil, _), do: {:error, :nil_object}
  def member?({:error, term}, _), do: {:error, term}

  @doc """
  Insert `value` on `set`
  """
  def put(set, value) when Record.is_record(set, :set) and is_binary(value) do
    :riakc_set.add_element(value, set)
  end
  def put(nil, _), do: {:error, :nil_object}
  def put({:error, term}, _), do: {:error, term}

  @doc """
  Delete `value` on `set`
  """
  def delete(set, value) when Record.is_record(set, :set) and is_binary(value) do
    :riakc_set.del_element(value, set)
  end
  def delete(nil, _), do: {:error, :nil_object}
  def delete({:error, term}, _), do: {:error, term}

  @doc """
  Returns the number of elements in `set`
  """
  def size(set) when Record.is_record(set, :set) do
    :riakc_set.size(set)
  end
  def size(nil), do: {:error, :nil_object}
  def size({:error, term}), do: {:error, term}
end
