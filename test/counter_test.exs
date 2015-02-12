defmodule Riak.CounterTest do
  use Riak.Case

  @counter_key "my_counter"

  test "increment", context do
    pid = context[:pid]

    assert :ok == Riak.Counter.enable(pid, "user")
    assert :ok == Riak.Counter.increment(pid, "user", @counter_key, 1)
    assert 1 == Riak.Counter.value(pid, "user", @counter_key)
  end

  test "decrement", context do
    pid = context[:pid]

    assert :ok == Riak.Counter.enable(pid, "user")
    assert :ok == Riak.Counter.increment(pid, "user", @counter_key, -1)
    assert -1 == Riak.Counter.value(pid, "user", @counter_key)
  end

end
