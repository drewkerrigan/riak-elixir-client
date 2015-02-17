defmodule Riak.Index do
  import Riak.Pool
  import :riakc_pb_socket

  defpool query(pid, bucket, {type, name}, key, opts) when is_pid(pid) do
    name = String.to_char_list(name)
    response = get_index_eq(pid, bucket, {type, name}, key, opts)
    handle_query_response(response)
  end

  defpool query(pid, bucket, {type, name}, startkey, endkey, opts) when is_pid(pid) do
    name = String.to_char_list(name)
    response = get_index_range(pid, bucket, {type, name}, startkey, endkey, opts)
    handle_query_response(response)
  end

  defp handle_query_response(response) do
    case response do
      {:ok, {:index_results_v1, keys, terms, continuation}} -> 
        {keys, terms, continuation}
      {:error, "{error,{indexes_not_supported,riak_kv_bitcask_backend}}"} ->
        Riak.I18n.error("error.index.unsupported")
      reason -> 
        Riak.I18n.error("error.index.default", reason: reason)
    end
  end
end
