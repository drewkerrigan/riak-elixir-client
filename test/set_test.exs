defmodule Riak.CRDT.SetTest do
  use Riak.Case
  alias Riak.CRDT.Set

  @moduletag :riak2

  test "create, update and find a set" do
    key = Riak.Helper.random_key

    Set.new
      |> Set.put("foo")
      |> Set.put("bar")
      |> Riak.update("sets", "bucketset", key)

    set = Riak.find("sets", "bucketset", key)
      |> Set.value

    assert "foo" in set
    assert "bar" in set
  end

  test "size" do
    key = Riak.Helper.random_key

    Set.new
      |> Set.put("foo") |> Set.put("bar")
      |> Set.put("foo") |> Set.put("bar")
      |> Riak.update("sets", "bucketset", key)

    size = Riak.find("sets", "bucketset", key)
      |> Set.size

    assert size == 2
  end
end
