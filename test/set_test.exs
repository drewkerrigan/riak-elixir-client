defmodule Riak.Datatype.SetTest do
  use Riak.Case
  alias Riak.Datatype.Set

  @moduletag :riak2

  test "create, update and find a set" do
    key = Riak.Helper.random_key
    bucket = {"sets", "bucketset"}

    Set.new(["foo", "bar"]) |> Riak.Datatype.put(bucket, key)
    set = Riak.Datatype.find(bucket, key)

    assert Set.member?(set, "foo")
    assert Set.member?(set, "bar")
  end

  test "size" do
    key = Riak.Helper.random_key
    bucket = {"sets", "bucketset"}

    Set.new(["foo", "bar"])
    |> Set.put("foo") |> Set.put("bar")
    |> Riak.Datatype.put(bucket, key)

    set = Riak.Datatype.find(bucket, key)

    assert Set.size(set) == 2
  end
end
