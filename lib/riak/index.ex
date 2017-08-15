defmodule Riak.Index do
  import Riak.Pool
  import :riakc_pb_socket

  @doc """
  @deprecated There are performance issues with 2i, please use another query strategy.
  Execute a secondary index equality query.
  """
  defpool query(pid, bucket, {type, name}, key, opts) when is_pid(pid) do
    name = String.to_charlist(name)
    response = get_index_eq(pid, bucket, {type, name}, key, opts)
    handle_query_response(response)
  end

  @doc """
  @deprecated There are performance issues with 2i, please use another query strategy.
  Execute a secondary index range query.
  """
  defpool query(pid, bucket, {type, name}, startkey, endkey, opts) when is_pid(pid) do
    name = String.to_charlist(name)
    response = get_index_range(pid, bucket, {type, name}, startkey, endkey, opts)
    handle_query_response(response)
  end

  defp handle_query_response(response) do
    case response do
      {:ok, {:index_results_v1, keys, terms, continuation}} -> 
        {keys, terms, continuation}
      {:error, term} -> {:error, term}
    end
  end
end
