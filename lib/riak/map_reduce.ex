defmodule Riak.Mapred do
  import Riak.Pool
  import :riakc_pb_socket

  @doc """
  @deprecated There are performance issues with MapReduce, please use another query strategy.
  Perform a MapReduce job across the cluster.
  See the MapReduce documentation for explanation of behavior.
  """
  defpool query(pid, inputs, query) when is_pid(pid), do: mapred(pid, inputs, query)
  defpool query(pid, inputs, query, timeout) when is_pid(pid), do: mapred(pid, inputs, query, timeout)

  defmodule Bucket do
    @doc """
    @deprecated There are performance issues with MapReduce, please use another query strategy.
    Perform a MapReduce job across the cluster using an entire bucket as the input.
    See the MapReduce documentation for explanation of behavior.
    """
    defpool query(pid, bucket, query) when is_pid(pid), do: mapred_bucket(pid, bucket, query)
    defpool query(pid, bucket, query, timeout) when is_pid(pid), do: mapred_bucket(pid, bucket, query, timeout)
  end
end
