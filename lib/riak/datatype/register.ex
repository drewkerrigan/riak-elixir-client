defmodule Riak.Datatype.Register do
  @moduledoc """
  Encapsulates a binary data to be used on CRDT.Map's
  """

  @opaque t :: %__MODULE__{
    value: String.t,
    new_value: String.t}
  defstruct value: "", new_value: nil

  @doc """
  Creates a new `map`
  """
  @spec new :: t
  def new(), do: %__MODULE__{}

  def new(%__MODULE__{} = register), do: register
  def new(new_value) do
    %__MODULE__{
      new_value: new_value
    }
  end
  def new(value, _context) do
    %__MODULE__{
      value: value
    }
  end

  @doc """
  Set the `value` on the `register`
  """
  def set(register, value) do
    %{register | new_value: value}
  end

  @doc """
  Extracts current value of `register`
  """
  def value(register), do: register.value

  def from_record({:register, value, new_value}) do
    %__MODULE__{
      value: value,
      new_value: to_nil(new_value)
    }
  end

  def to_record(register) do
    {:register, register.value, to_undefined(register.new_value)}
  end

  def to_op(_), do: :undefined

  def to_nil(nil), do: nil
  def to_nil(:undefined), do: nil
  def to_nil(v), do: v

  def to_undefined(nil), do: :undefined
  def to_undefined(:undefined), do: :undefined
  def to_undefined(v), do: v

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(register, opts) do
      concat ["#" <> Atom.to_string(__MODULE__) <> "<", Inspect.Map.inspect(Map.from_struct(register), opts), ">"]
    end
  end
end
