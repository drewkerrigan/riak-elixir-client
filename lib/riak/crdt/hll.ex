defmodule Riak.CRDT.HyperLogLog do
  @moduledoc """
  Encapsulates Riak HLL
  """
  require Record

  @doc """
  Creates a new `hll`
  """
  def new, do: :riakc_hll.new

  @doc """
  Adds a distinct element to the HLL
  """
  def add_element(hll, elm), do: :riakc_hll.add_element(elm, hll)
  def add_elements(hll, list), do: :riakc_hll.add_elements(list, hll)

  @doc """
  Fetch the value of the HLL
  """
  def value(hll), do: :riakc_hll.value(hll)
end
