defmodule Riak.BucketTest do
  use Riak.Case

  @moduletag :riak1

  test "list bucket", context do
    {:ok, buckets} = Riak.Bucket.list context[:pid]
    assert is_list(buckets)
  end

  test "list! bucket", context do
    buckets = Riak.Bucket.list! context[:pid]
    assert is_list(buckets)
  end

  test "list keys", context do
    {:ok, keys} = Riak.Bucket.keys context[:pid], "user"
    assert is_list(keys)
  end

  test "list! keys", context do
    keys = Riak.Bucket.keys! context[:pid], "user"
    assert is_list(keys)
  end

  test "bucket props", context do
    pid = context[:pid]
    assert :ok == Riak.Bucket.put pid, "user", [{:notfound_ok, false}]

    {:ok, props} = Riak.Bucket.get pid, "user"
    assert is_list(props)
    assert props[:notfound_ok] == false

    assert :ok == Riak.Bucket.reset pid, "user"

    {:ok, props} = Riak.Bucket.get pid, "user"
    assert props[:notfound_ok] == true
  end
end
