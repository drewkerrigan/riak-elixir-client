defmodule Riak.PoolTest do
  use Riak.Case
  import Riak.Helper

  @moduletag :riak1

  test "put" do
    key = random_key()

    o =  Riak.Object.create(bucket: "user", key: key, data: "Drew Kerrigan")

    assert Riak.put(o) == o
    assert Riak.put(:riak, o) == o
  end
end
