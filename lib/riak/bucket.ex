defmodule Riak.Bucket do
  import Riak.Pool
  import :riakc_pb_socket, except: [put: 3, put: 4]

  defpool list(pid) when is_pid(pid), do: list_buckets(pid)
  defpool list(pid, timeout) when is_pid(pid), do: list_buckets(pid, timeout)

  defpool list!(pid) when is_pid(pid) do
    {:ok, buckets} = list(pid)
    buckets
  end
  defpool list!(pid, timeout) when is_pid(pid) do
    {:ok, buckets} = list(pid, timeout)
    buckets
  end

  defpool keys(pid, bucket) when is_pid(pid), do: list_keys(pid, bucket)
  defpool keys(pid, bucket, timeout) when is_pid(pid), do: list_keys(pid, bucket, timeout)

  defpool keys!(pid, bucket) when is_pid(pid) do
    {:ok, keys} = keys(pid, bucket)
    keys
  end
  defpool keys!(pid, bucket, timeout) when is_pid(pid) do
    {:ok, keys} = keys(pid, bucket, timeout)
    keys
  end

  defpool get(pid, bucket) when is_pid(pid), do: get_bucket(pid, bucket)

  defpool put(pid, bucket, props) when is_pid(pid), do: set_bucket(pid, bucket, props)
  defpool put(pid, bucket, type, props) when is_pid(pid) do
    set_bucket(pid, {type, bucket}, props)
  end

  defpool reset(pid, bucket) when is_pid(pid), do: reset_bucket(pid, bucket)

  defmodule Type do
    defpool get(pid, type) when is_pid(pid), do: get_bucket_type(pid, type)
    defpool put(pid, type, props) when is_pid(pid), do: set_bucket_type(pid, type, props)
    defpool reset(pid, bucket) when is_pid(pid), do: reset_bucket(pid, bucket)

    defpool list(pid, type) when is_pid(pid), do: list_buckets(pid, type)

    defpool list!(pid, type) when is_pid(pid) do
      {:ok, buckets} = list(pid, type)
      buckets
    end

    def keys(pid, type, bucket) when is_pid(pid), do: Riak.Bucket.keys(pid, {type, bucket})
    def keys(pid, type, bucket, timeout) when is_pid(pid), do: Riak.Bucket.keys(pid, {type, bucket}, timeout)
    def keys!(pid, type, bucket) when is_pid(pid), do: Riak.Bucket.keys!(pid, {type, bucket})
    def keys!(pid, type, bucket, timeout) when is_pid(pid), do: Riak.Bucket.keys!(pid, {type, bucket}, timeout)
  end

  # This is important to "register" the atoms
  def possible_props do
    [n_val: 3, old_vclock: 86400, young_vclock: 20, big_vclock: 50, small_vclock: 50, allow_mult: false, last_write_wins: false,
      basic_quorum: false, notfound_ok: false, precommit: [], postcommit: [], chash_keyfun: {:riak_core_util, :chash_std_keyfun},
      linkfun: {:modfun, :riak_kv_wm_link_walker, :mapreduce_linkfun}, pr: 0, r: :quorum, w: :quorum, pw: 0, dw: :quorum,
      rw: :quorum]
  end
end

