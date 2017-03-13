defmodule Riak.Datatype.Set do
  @moduledoc """
  Encapsulates riakc_set.
  It accepts only binary as items.
  """
  require Record

  @opaque t :: %__MODULE__{
    value: MapSet,
    adds: MapSet,
    removes: MapSet,
    context: binary | nil}
  defstruct value: MapSet.new, adds: MapSet.new, removes: MapSet.new, context: nil

  @doc """
  Creates a new `set`
  """
  @spec new :: t
  def new(), do: %__MODULE__{}

  def new(%__MODULE__{} = set), do: set
  def new(enumerable) do
    %__MODULE__{
      adds: MapSet.new(enumerable)
    }
  end
  def new(enumerable, context) do
    %__MODULE__{
      value: MapSet.new(enumerable),
      context: context
    }
  end

  def delete(set, key) do
    %{set | removes: MapSet.put(set.removes, key)}
  end
  def difference(set1, set2) do
    MapSet.difference(set1.value, set2.value)
  end
  def disjoint?(set1, set2) do
    MapSet.disjoint?(set1.value, set2.value)
  end
  def equal?(set1, set2), do: MapSet.equal?(set1.value, set2.value)
  def intersection(set1, set2), do: MapSet.intersection(set1.value, set2.value)
  def member?(set, value), do: MapSet.member?(set.value, value)
  def put(set, value) do
    %{set | adds: MapSet.put(set.adds, value)}
  end
  def size(set), do: MapSet.size(set.value)
  def subset?(set1, set2), do: MapSet.subset?(set1.value, set2.value)
  def to_list(set), do: MapSet.to_list(set.value)
  def union(set1, set2), do: MapSet.union(set1.value, set2.value)
  def values(set), do: to_list(set)
  def value(set), do: to_list(set)

  def from_record({:set, value, adds, removes, context}) do
    value = MapSet.new(value)
    adds = MapSet.new(adds)
    removes = MapSet.new(removes)
    %__MODULE__{
      value: value,
      adds: adds,
      removes: removes,
      context: to_nil(context)
    }
  end

  def to_record(set) do
    {:set,
     MapSet.to_list(set.value),
     MapSet.to_list(set.adds),
     MapSet.to_list(set.removes),
     to_undefined(set.context),
    }
  end

  def to_op(set), do: to_record(set) |> :riakc_set.to_op

  def to_nil(nil), do: nil
  def to_nil(:undefined), do: nil
  def to_nil(v), do: v

  def to_undefined(nil), do: :undefined
  def to_undefined(:undefined), do: :undefined
  def to_undefined(v), do: v

  defimpl Enumerable do
    def count(map), do: Enumerable.Map.count(map.value)
    def member?(map, item), do: Enumerable.Map.member?(map.value, item)
    def reduce(map, acc, fun), do: Enumerable.Map.reduce(map.value, acc, fun)
  end

  defimpl Collectable do
    def into(original) do
      {original, fn
        set, {:cont, v} -> Riak.Datatype.Set.put(set, v)
        set, :done -> set
        _, :halt -> :ok
      end}
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(set, opts) do
      concat ["#" <> Atom.to_string(__MODULE__) <> "<", Inspect.Map.inspect(Map.from_struct(set), opts), ">"]
    end
  end
end
