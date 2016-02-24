defmodule Riak.Timeseries do
  import Riak.Pool

  defpool query(pid, query_text) when is_pid(pid) do
    :riakc_ts.query(pid, query_text)
  end

  defpool put(pid, table, data) when is_pid(pid)  and is_list(data)do
    :riakc_ts.put(pid, table, data)
  end

  defpool get(pid, table, key) when is_pid(pid) and is_list(key) do
    get(pid, table, key, [])
  end

  defpool get(pid, table, key, options) when is_pid(pid) and is_list(key) do
    :riakc_ts.get(pid, table, key, options)
  end

  defpool delete(pid, table, key) when is_pid(pid) and is_list(key) do
    delete(pid, table, key, [])
  end

  defpool delete(pid, table, key, options) when is_pid(pid) and is_list(key) do
    :riakc_ts.delete(pid, table, key, options)
  end

  defpool list!(pid, table) when is_pid(pid) do
    list!(pid, table, [])
  end

  defpool list!(pid, table, options) when is_pid(pid) do
    {:ok, req_id} = :riakc_ts.stream_list_keys(pid, table, options)
    wait_for_list(req_id, [])
  end

  defp wait_for_list(req_id, acc) do
    receive do
      {^req_id, :done} -> {:ok, List.flatten(acc)}
      {^req_id, {:error, reason}} -> {:error, reason}
      {req_id, {_, res}} -> wait_for_list(req_id, [res|acc])
    end
  end
end
