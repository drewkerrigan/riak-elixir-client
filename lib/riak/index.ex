defmodule Riak.Index do
  import Riak.Pool
  import :riakc_pb_socket

  defpool query(pid, bucket, {type, name}, key, opts) when is_pid(pid) do
    name = String.to_char_list(name)
    case get_index_eq(pid, bucket, {type, name}, key, opts) do
      {:ok, {:index_results_v1, keys, terms, continuation}} -> {keys, terms, continuation}
      res -> res
    end
  end

  defpool query(pid, bucket, {type, name}, startkey, endkey, opts) when is_pid(pid) do
    name = String.to_char_list(name)
    case get_index_range(pid, bucket, {type, name}, startkey, endkey, opts) do
      {:ok, {:index_results_v1, keys, terms, continuation}} -> {keys, terms, continuation}
      res -> res
    end
  end
end
