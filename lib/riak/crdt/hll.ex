defmodule Riak.CRDT.HyperLogLog do
  @moduledoc """
  Encapsulates Riak HLL
  """
  require Record

  @doc """
  Creates a new `hll`
  """
  def new(), do: :riakc_hll.new()

  @doc """
  Adds a distinct element to the HLL
  """
  def add_element(hll, elm), do: :riakc_hll.add_element(elm, hll)

  @doc """
  Adds a list of elements to the HLL
  """
  def add_elements(nil, _), do: {:error, :nil_object}
  def add_elements({:error, term}, _), do: {:error, term}
  def add_elements(hll, list) when is_list(list), do: :riakc_hll.add_elements(list, hll)

  @doc """
  Fetch the value of the HLL
  """
  def value(nil), do: {:error, :nil_object}
  def value({:error, term}), do: {:error, term}
  def value(hll), do: :riakc_hll.value(hll)
end
