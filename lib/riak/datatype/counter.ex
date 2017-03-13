defmodule Riak.Datatype.Counter do
  @moduledoc """
  Counter data-type on Riak 2.0.
  """

  @opaque t :: %__MODULE__{
    value: integer,
    increment: integer}
  defstruct value: 0, increment: nil

  require Record

  @doc """
  Creates a new `map`
  """
  @spec new :: t
  def new(), do: %__MODULE__{}

  def new(%__MODULE__{} = counter), do: counter
  def new(increment) do
    %__MODULE__{
      increment: increment
    }
  end
  def new(value, _context) do
    %__MODULE__{
      value: value
    }
  end

  @doc """
  Increment a `counter` on the `amount` defaulting in 1
  """
  def increment(counter, amount \\ 1) do
    case counter.increment do
      nil ->
        %{counter | increment: amount}
      val ->
        %{counter | increment: val + amount}
    end
  end

  @doc """
  Decrement a `counter` on the `amount` defaulting in 1
  """
  def decrement(counter, amount \\ 1) do
    increment(counter, -amount)
  end

  def value(counter), do: counter.value

  def from_record({:counter, value, increment}) do
    %__MODULE__{
      value: value,
      increment: to_nil(increment)
    }
  end

  def to_record(counter) do
    {:counter, counter.value, to_undefined(counter.increment)}
  end

  def to_op(counter), do: to_record(counter) |> :riakc_counter.to_op

  def to_nil(nil), do: nil
  def to_nil(:undefined), do: nil
  def to_nil(v), do: v

  def to_undefined(nil), do: :undefined
  def to_undefined(:undefined), do: :undefined
  def to_undefined(v), do: v

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(counter, opts) do
      concat ["#" <> Atom.to_string(__MODULE__) <> "<", Inspect.Map.inspect(Map.from_struct(counter), opts), ">"]
    end
  end
end
