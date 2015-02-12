defmodule Riak.Counter do
  import Riak.Pool
  import :riakc_pb_socket

  defpool enable(pid, bucket) when is_pid(pid), do: Riak.Bucket.put(pid, "#{bucket}-counter", [{:allow_mult, true}])

  defpool increment(pid, bucket, name, amount) when is_pid(pid) do
    counter_incr(pid, "#{bucket}-counter", name, amount)
  end

  defpool value(pid, bucket, name) when is_pid(pid) do
    case counter_val(pid, "#{bucket}-counter", name) do
      {:ok, val} -> val
      val -> val
    end
  end
end
