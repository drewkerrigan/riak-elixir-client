defmodule Riak.PoolTest do
  use Riak.Case
  import Riak.Helper

  test "put" do
    key = random_key

    o =  Riak.Object.create(bucket: "user", key: key, data: "Drew Kerrigan")

    assert Riak.put(o) == o
  end
end
