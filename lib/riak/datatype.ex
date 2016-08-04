defmodule Riak.Datatype do
  @moduledoc """
  Common CRDT module
  """

  import Riak.Pool
  require Record

  @doc """
  Updates the convergent datatype in Riak with local
  modifications stored in the container type. Equivalent to `update`
  """
  defpool put(pid, datatype, {_bucket_type, _bucket}=b, key) when is_pid(pid) do
    update(pid, datatype, b, key)
  end
  defpool put(pid, datatype, bucket_type, bucket, key) when is_pid(pid) do
    update(pid, datatype, {bucket_type, bucket}, key)
  end

  @doc """
  Updates the convergent datatype in Riak with local
  modifications stored in the container type.
  """
  defpool update(pid, datatype, {_bucket_type, _bucket}=b, key) when is_pid(pid) do
    :riakc_pb_socket.update_type(pid, b, key, to_op(datatype))
  end
  defpool update(pid, datatype, bucket_type, bucket, key) when is_pid(pid) do
    update(pid, datatype, {bucket_type, bucket}, key)
  end

  @doc """
  Fetches the representation of a convergent datatype from Riak.
  """
  defpool find(pid, {_bucket_type, _bucket}=b, key) when is_pid(pid) do
    case :riakc_pb_socket.fetch_type(pid, b, key) do
      {:ok, rec} -> from_record(rec)
      _ -> nil
    end
  end
  defpool find(pid, bucket_type, bucket, key) when is_pid(pid) do
    find(pid, {bucket_type, bucket}, key)
  end

  @doc """
  Delete the key/value.
  """
  defpool delete(pid, {_bucket_type, _bucket}=b, key) when is_pid(pid), do: :riakc_pb_socket.delete(pid, b, key)
  defpool delete(pid, bucket_type, bucket, key) when is_pid(pid), do: delete(pid, {bucket_type, bucket}, key)

  @datatypes [
    {:set, Riak.Datatype.Set, :is_list},
    {:counter, Riak.Datatype.Counter, :is_integer},
    {:register, Riak.Datatype.Register, :is_binary},
    {:flag, Riak.Datatype.Flag, :is_boolean},
    {:map, Riak.Datatype.Map, :is_map}
  ]

  Enum.each @datatypes, fn {t, m, f} ->
    def type(%unquote(m){}), do: unquote(t)

    def type(unquote(m)), do: unquote(t)

    def type(v) when unquote(f)(v), do: unquote(t)

    def new(%unquote(m){}=v), do: unquote(m).new(v)

    def new(v) when unquote(f)(v), do: unquote(m).new(v)

    def new(%unquote(m){}=v, c), do: unquote(m).new(v, c)

    def new(v, c) when unquote(f)(v), do: unquote(m).new(v, c)

    def value(%unquote(m){}=v), do: unquote(m).value(v)

    def to_op(%unquote(m){}=v), do: unquote(m).to_op(v)

    def to_record(%unquote(m){}=v), do: unquote(m).to_record(v)

    def from_record(rec) when Record.is_record(rec, unquote(t)), do: unquote(m).from_record(rec)
  end
end
