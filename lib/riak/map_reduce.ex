defmodule Riak.Mapred do
  import Riak.Pool
  import :riakc_pb_socket

  defpool query(pid, inputs, query) when is_pid(pid), do: mapred(pid, inputs, query)
  defpool query(pid, inputs, query, timeout) when is_pid(pid), do: mapred(pid, inputs, query, timeout)

  defmodule Bucket do
    defpool query(pid, bucket, query) when is_pid(pid), do: mapred_bucket(pid, bucket, query)
    defpool query(pid, bucket, query, timeout) when is_pid(pid), do: mapred_bucket(pid, bucket, query, timeout)
  end
end
