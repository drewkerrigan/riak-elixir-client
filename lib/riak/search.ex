defmodule Riak.Search do
  import Riak.Pool
  import :riakc_pb_socket, except: [put: 2, put: 3, put: 4]

  defpool query(pid, index, query) when is_pid(pid), do: search(pid, index, query)
  defpool query(pid, index, query, options) when is_pid(pid), do: search(pid, index, query, options)
  defpool query(pid, index, query, options, timeout) when is_pid(pid), do: search(pid, index, query, options, timeout)

  defmodule Index do
    defpool list(pid) when is_pid(pid), do: list_search_indexes(pid)
    defpool put(pid, index) when is_pid(pid), do: create_search_index(pid, index)
    defpool put(pid, index, schema) when is_pid(pid), do: create_search_index(pid, index, schema, [])
    defpool put(pid, index, schema, props) when is_pid(pid), do: create_search_index(pid, index, schema, props)
    defpool get(pid, index) when is_pid(pid), do: get_search_index(pid, index)
    defpool set(pid, bucket, index) when is_pid(pid), do: set_search_index(pid, bucket, index)
    defpool delete(pid, index) when is_pid(pid), do: delete_search_index(pid, index)
  end

  defmodule Schema do
    defpool get(pid, schema) when is_pid(pid), do: get_search_schema(pid, schema)

    defpool create(pid, schema, content) when is_pid(pid) do
      create_search_schema(pid, schema, content)
    end
  end
end
