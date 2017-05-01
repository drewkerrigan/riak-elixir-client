defmodule Riak.CRDT.HyperLogLogTest do
  use Riak.Case
  alias Riak.CRDT.HyperLogLog

  @moduletag :riak2

  test "create, update and find a hll" do
    key = Riak.Helper.random_key

    HyperLogLog.new
      |> HyperLogLog.add_element("One")
      |> HyperLogLog.add_elements(["Two", "Three", "One", "Two"])
      |> Riak.update("hll", "buckethll", key)

    counter = Riak.find("hll", "buckethll", key)
      |> HyperLogLog.value

    assert counter == 3
  end
end
