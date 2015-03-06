defmodule Riak.Bucket do
  import Riak.Pool
  import :riakc_pb_socket, except: [put: 3, put: 4]

  @doc """
  List all buckets on the server with or without server-side timeout.
  ***This is a potentially expensive operation and should not be used in production.***
  """
  defpool list(pid) when is_pid(pid), do: list_buckets(pid)
  defpool list(pid, timeout) when is_pid(pid), do: list_buckets(pid, timeout)

  @doc """
  List all buckets on the server with or without server-side timeout. Return only buckets.
  ***This is a potentially expensive operation and should not be used in production.***
  """
  defpool list!(pid) when is_pid(pid) do
    {:ok, buckets} = list(pid)
    buckets
  end
  defpool list!(pid, timeout) when is_pid(pid) do
    {:ok, buckets} = list(pid, timeout)
    buckets
  end

  @doc """
  List all keys in a bucket.
  ***This is a potentially expensive operation and should not be used in production.***
  """
  def keys(pid, type, bucket) when is_pid(pid) and is_binary(bucket), do: keys(pid, {type, bucket})
  def keys(pid, type, bucket, timeout) when is_pid(pid), do: keys(pid, {type, bucket}, timeout)
  defpool keys(pid, bucket) when is_pid(pid), do: list_keys(pid, bucket)
  defpool keys(pid, bucket, timeout) when is_pid(pid), do: list_keys(pid, bucket, timeout)

  @doc """
  List all keys in a bucket. Return only buckets.
  ***This is a potentially expensive operation and should not be used in production.***
  """
  def keys!(pid, type, bucket) when is_pid(pid) and is_binary(bucket), do: keys!(pid, {type, bucket})
  def keys!(pid, type, bucket, timeout) when is_pid(pid), do: keys!(pid, {type, bucket}, timeout)
  defpool keys!(pid, bucket) when is_pid(pid) do
    {:ok, keys} = keys(pid, bucket)
    keys
  end
  defpool keys!(pid, bucket, timeout) when is_pid(pid) do
    {:ok, keys} = keys(pid, bucket, timeout)
    keys
  end

  @doc """
  Get bucket properties.
  """
  defpool get(pid, bucket) when is_pid(pid), do: get_bucket(pid, bucket)

  @doc """
  Set bucket properties.
  """
  defpool put(pid, bucket, props) when is_pid(pid), do: set_bucket(pid, bucket, props)
  defpool put(pid, bucket, type, props) when is_pid(pid) do
    set_bucket(pid, {type, bucket}, props)
  end

  @doc """
  Reset bucket properties back to the defaults.
  """
  defpool reset(pid, bucket) when is_pid(pid), do: reset_bucket(pid, bucket)

  defmodule Type do
    @doc """
    Get properties for bucket type.
    """
    defpool get(pid, type) when is_pid(pid), do: get_bucket_type(pid, type)

    @doc """
    Set properties for bucket type.
    """
    defpool put(pid, type, props) when is_pid(pid), do: set_bucket_type(pid, type, props)

    defpool list(pid, type) when is_pid(pid) and is_binary(type), do: list_buckets(pid, type)
    defpool list(pid, type, timeout) when is_pid(pid), do: list_buckets(pid, type, timeout)

    defpool list!(pid, type) when is_pid(pid) and is_binary(type) do
      {:ok, buckets} = list(pid, type)
      buckets
    end
    defpool list!(pid, type, timeout) when is_pid(pid) do
      {:ok, buckets} = list(pid, type, timeout)
      buckets
    end
  end

  @doc """
  Used to "register" the atoms used by the protobuf interface, not for public use.
  """
  def possible_props do
    [n_val: 3, old_vclock: 86400, young_vclock: 20, big_vclock: 50, small_vclock: 50, allow_mult: false, last_write_wins: false,
      basic_quorum: false, notfound_ok: false, precommit: [], postcommit: [], chash_keyfun: {:riak_core_util, :chash_std_keyfun},
      linkfun: {:modfun, :riak_kv_wm_link_walker, :mapreduce_linkfun}, pr: 0, r: :quorum, w: :quorum, pw: 0, dw: :quorum,
      rw: :quorum]
  end
end

