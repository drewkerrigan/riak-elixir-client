defmodule Riak do
  @moduledoc """
  A Client for Riak.

  ## Setup
  The `start` function starts the OTP application, and `configure`
  sends a message to the OTP server running locally which starts
  the protobuf link with your Riak cluster.

      iex> Riak.Connection.start_link

  The client supports secondary indexes. Remember to use a storage
  backend that support secondary indexes (such as *leveldb*), in
  your Riak configuration.

  ## Basic CRUD operations
  Data is inserted into the database using the `put` function. The
  inserted data needs to be an `RObj` created like this:

      iex> u = RObj.create(bucket: "user", key: "my_key", data: "Drew Kerrigan")
      iex> Riak.put pid, u

  To get a data entry out of the database, use the `find` function.

      iex> u = Riak.find pid, "user", "my_key"

  Updating data is done with by fetching a data entry, updating its
  data and putting it back into the database using `find` and `put`.

      iex> u = Riak.find pid, "user", "my_key"
      iex> u = u.data("Updated Data")
      iex> Riak.put pid, u

  Deleting data from the database is done using the `delete` function.

      iex> Riak.delete pid, "user", "my_key"

  The client support secondary indexes, links and siblings. This is
  work in progress, and any help is greatly appreciated.
  """
  import Riak.Pool
  require Record

  defpool ping(pid) when is_pid(pid), do: :riakc_pb_socket.ping(pid)

  defpool put(pid, obj) when is_pid(pid) do
    case :riakc_pb_socket.put(pid, Riak.Object.to_robj(obj)) do
      {:ok, new_object} -> %{obj | key: :riakc_obj.key(new_object)}
      :ok -> obj
      _ -> nil
    end
  end

  defpool update(pid, datatype, type, bucket, key) when is_pid(pid) do
    :riakc_pb_socket.update_type(pid, {type, bucket},
                                 key, to_op(datatype))
  end

  defp to_op(datatype) do
    case datatype do
      datatype when Record.is_record(datatype, :set) ->
        :riakc_set.to_op(datatype)
      datatype when Record.is_record(datatype, :counter) ->
        :riakc_counter.to_op(datatype)
      datatype when Record.is_record(datatype, :map) ->
        :riakc_map.to_op(datatype)
      _ -> :undefined
    end
  end

  defpool find(pid, bucket, key) when is_pid(pid) do
    case :riakc_pb_socket.get(pid, bucket, key) do
      {:ok, object} ->
        if :riakc_obj.value_count(object) > 1 do
          build_sibling_list(:riakc_obj.get_contents(object),[])
        else
          Riak.Object.from_robj(object)
        end
      _ -> nil
    end
  end

  defpool find(pid, type, bucket, key) when is_pid(pid) do
    case :riakc_pb_socket.fetch_type(pid, {type, bucket}, key) do
      {:ok, object} -> object
      _ -> nil
    end
  end

  defp build_sibling_list([{_md, val}|t], final_list), do: build_sibling_list(t,[val|final_list])
  defp build_sibling_list([], final_list), do: final_list

  defpool resolve(pid, bucket, key, index) when is_pid(pid) do
    case :riakc_pb_socket.get(pid, bucket, key) do
      {:ok, object} ->
        new_object = :riakc_obj.select_sibling(index, object)
        :riakc_pb_socket.put(pid, new_object)
      _ -> nil
    end
  end

  defpool delete(pid, obj) when is_pid(pid), do: delete(pid, obj.bucket, obj.key)
  defpool delete(pid, bucket, key) when is_pid(pid), do: :riakc_pb_socket.delete(pid, bucket, key)
end
