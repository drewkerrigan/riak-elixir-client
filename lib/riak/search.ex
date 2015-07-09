defmodule Riak.Search do
  import :riakc_pb_socket

  def query(pid, bucket, query, options \\ []) when is_pid(pid), do: search(pid, bucket, query, options)
  def query(pid, bucket, query, options, timeout) when is_pid(pid), do: search(pid, bucket, query, options, timeout)

  defmodule Index do
    def list(pid) when is_pid(pid), do: list_search_indexes(pid)
    def put(pid, bucket) when is_pid(pid), do: create_search_index(pid, bucket)
    def put(pid, bucket, schema) when is_pid(pid), do: create_search_index(pid, bucket, schema, [])
    def put(pid, bucket, schema, props) when is_pid(pid), do: create_search_index(pid, bucket, schema, props)
    def get(pid, bucket) when is_pid(pid), do: get_search_index(pid, bucket)
    def delete(pid, bucket) when is_pid(pid), do: delete_search_index(pid, bucket)
  end

  defmodule Schema do
    def get(pid, bucket) when is_pid(pid), do: get_search_schema(pid, bucket)

    def create(pid, bucket, content) when is_pid(pid) do
      create_search_schema(pid, bucket, content)
    end
  end
end
