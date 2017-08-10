defmodule Riak.CRDT.Map do
  @moduledoc """
  Encapsulates Riak maps
  """
  require Record

  @doc """
  Creates a new `map`
  """
  def new(), do: :riakc_map.new()

  @doc """
  Get the `map` size
  """
  def size(map) when Record.is_record(map, :map), do: :riakc_map.size(map)
  def size(nil), do: {:error, :nil_object}
  def size({:error, term}), do: {:error, term}

  @doc """
  Fetch the value associated to `key` with the `key_type` on `map`
  """
  def get(map, key_type, key) when Record.is_record(map, :map) do
    :riakc_map.fetch({key, key_type}, map)
  end
  def get(nil, _, _), do: {:error, :nil_object}
  def get({:error, term}, _, _), do: {:error, term}

  @doc """
  Update the `key` on the `map` by passing the function `fun`
  to update the value based on the current value (if exists) as argument
  The key_type must be :register, :map, :set, :flag or :counter
  """
  def update(map, key_type, key, fun) when Record.is_record(map, :map)
                                      and is_atom(key_type)
                                      and is_binary(key)
                                      and is_function(fun, 1) do

    :riakc_map.update({key, key_type}, fun, map)
  end
  def update(nil, _, _, _), do: {:error, :nil_object}
  def update({:error, term}, _, _, _), do: {:error, term}

  @doc """
  Update the `key` on the `map` by passing the `value`
  The value can be any other CRDT
  """
  def put(map, key, value) when Record.is_record(map, :map)
                              and is_binary(key) do
    key_type = Riak.CRDT.type(value)
    fun = fn _ -> value end
    :riakc_map.update({key, key_type}, fun, map)
  end
  def put(nil, _, _), do: {:error, :nil_object}
  def put({:error, term}, _, _), do: {:error, term}

  @doc """
  Delete a `key` from the `map`
  """
  def delete(map, key) when Record.is_record(map, :map) do
    :riakc_map.erase(key, map)
  end
  def delete(nil, _), do: {:error, :nil_object}
  def delete({:error, term}, _), do: {:error, term}

  @doc """
  Get the original value of the `map`
  """
  def value(map) when Record.is_record(map, :map), do: :riakc_map.value(map)
  def value(nil), do: {:error, :nil_object}
  def value({:error, term}), do: {:error, term}

  @doc """
  List all keys of the `map`
  """
  def keys(map) when Record.is_record(map, :map), do: :riakc_map.fetch_keys(map)
  def keys(nil), do: {:error, :nil_object}
  def keys({:error, term}), do: {:error, term}

  @doc """
  Test if the `key` is contained in the `map`
  """
  def has_key?(map, key) when Record.is_record(map, :map) do
    :riakc_map.is_key(key, map)
  end
  def has_key?(nil, _), do: {:error, :nil_object}
  def has_key?({:error, term}, _), do: {:error, term}
end
