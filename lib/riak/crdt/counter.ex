defmodule Riak.CRDT.Counter do
  @moduledoc """
  Counter data-type on Riak 2.0.
  """
  require Record

  @doc """
  Create a new counter
  """
  def new, do: :riakc_counter.new

  @doc """
  Increment a `counter` on the `amount` defaulting in 1
  """
  def increment(counter, amount \\ 1) when Record.is_record(counter, :counter) do
    :riakc_counter.increment(amount, counter)
  end
  def increment(nil, _), do: {:error, :nil_object}

  @doc """
  Decrement a `counter` on the `amount` defaulting in 1
  """
  def decrement(counter, amount \\ 1) when Record.is_record(counter, :counter) do
    :riakc_counter.increment(-amount, counter)
  end
  def decrement(nil, _), do: {:error, :nil_object}

  @doc """
  Get the original value as a number
  """
  def value(counter) when Record.is_record(counter, :counter) do
    :riakc_counter.value(counter)
  end
  def value(nil), do: {:error, :nil_object}
end
