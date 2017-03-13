defmodule Riak.Object do
  @moduledoc """
  The Data wrapper makes it convenient to work with Riak data in Elixir
  """

  @md_ctype "content-type"
  @md_charset "charset"
  @md_encoding "content-encoding"
  @md_vtag "X-Riak-VTag"
  @md_links "Links"
  @md_lastmod "X-Riak-Last-Modified"
  @md_usermeta "X-Riak-Meta"
  @md_index "index"
  @md_deleted "X-Riak-Deleted"

  @opaque t :: %__MODULE__{
    type: String.t(),
    bucket: String.t(),
    key: String.t(),
    data: binary,
    siblings: list,
    context: binary,
    content_type: String.t(),
    charset: String.t(),
    content_encoding: String.t(),
    vtag: String.t(),
    links: MapSet,
    last_modified: String.t(),
    indexes: map,
    metadata: map,
    deleted: boolean
  }

  defstruct [
    type: "default",
    bucket: nil,
    key: nil,
    old_data: nil,
    data: nil,
    siblings: [],
    context: nil,
    content_type: "application/json",
    charset: nil,
    content_encoding: nil,
    vtag: nil,
    links: MapSet.new(),
    last_modified: nil,
    indexes: %{},
    metadata: %{},
    deleted: false]

  @spec new :: t
  def new(), do: %__MODULE__{}

  def new(%__MODULE__{} = set), do: set
  def new(enumerable) do
    struct(__MODULE__, Enum.to_list(enumerable))
  end

  # Compatibility
  def create(enumerable) do
    struct(__MODULE__, Enum.to_list(enumerable))
  end

  def from_record({:riakc_obj, {type, bucket}, key, context, [{md, data}], :undefined, :undefined}) do
    obj = from_md_dict(md)
    %{obj |
      type: type,
      bucket: bucket,
      key: key,
      data: data,
      context: context
    }
  end

  def from_record({:riakc_obj, {type, bucket}, key, context, [{_, _}|_], _, _}=rec) do
    %__MODULE__{
      type: type,
      bucket: bucket,
      key: key,
      data: nil,
      context: context,
      siblings: from_record_siblings(rec, [])
    }
  end

  def from_record({:riakc_obj, bucket, key, context, md, :undefined, :undefined}=rec) do
    from_record({:riakc_obj, {"default", bucket}, key, context, md, :undefined, :undefined})
  end

  def from_record_siblings({:riakc_obj, _, _, _, [], _, _}, acc) do
    acc
  end

  def from_record_siblings({:riakc_obj, {type, bucket}, key, context, [{md, data}|rest], um, ud}, acc) do
    sibling = from_record({:riakc_obj, {type, bucket}, key, context, [{md, data}], um, ud})
    next = {:riakc_obj, {type, bucket}, key, context, rest, um, ud}
    from_record_siblings(next, [sibling | acc])
  end

  def to_record(obj) do
    obj = obj
    |> fix_bucket

    {:riakc_obj,
     {obj.type, obj.bucket},
     to_undefined(obj.key),
     to_undefined(obj.context),
     [],
     to_md_dict(obj),
     obj.data}
  end

  # Compatibility
  def from_robj(rec) do
    from_record(rec)
  end

  # Compatibility
  def to_robj(obj) do
    to_record(obj)
  end

  # Compatibility
  def get_metadata(obj, key) do
    Map.get(obj.metadata, key)
  end

  # Compatibility
  def get_all_metadata(obj) do
    obj.metadata
  end

  # Compatibility
  def delete_metadata(obj, key) do
    %__MODULE__{
      obj | metadata: Map.delete(obj.metadata, key)
    }
  end

  # Compatibility
  def delete_all_metadata(obj) do
    %__MODULE__{
      obj | metadata: %{}
    }
  end

  # Compatibility
  def put_metadata(obj, {key, value}) do
    %__MODULE__{
      obj | metadata: Map.put(obj.metadata, key, value)
    }
  end
  def put_metadata(obj, key, value) do
    %__MODULE__{
      obj | metadata: Map.put(obj.metadata, key, value)
    }
  end

  # def index_id({:binary_index, name}), do: "#{name}_bin"
  # def index_id({:integer_index, name}), do: "#{name}_int"

  # Compatibility
  def get_index(obj, {_type, name}) do
    Map.get(obj.indexes, name)
  end
  def get_index(obj, name) do
    Map.get(obj.indexes, name)
  end

  # Compatibility
  def get_all_indexes(obj) do
    obj.indexes
  end

  # Compatibility
  def delete_index(obj, {_type, name}) do
    %__MODULE__{
      obj | indexes: Map.delete(obj.indexes, name)
    }
  end
  def delete_index(obj, name) do
    %__MODULE__{
      obj | indexes: Map.delete(obj.indexes, name)
    }
  end

  # Compatibility
  def delete_all_indexes(obj) do
    %__MODULE__{
      obj | indexes: %{}
    }
  end

  # Compatibility
  def put_index(obj, {_type, name}, values) do
    %__MODULE__{
      obj | indexes: Map.put(obj.indexes, name, values)
    }
  end
  def put_index(obj, name, values) do
    %__MODULE__{
      obj | indexes: Map.put(obj.indexes, name, values)
    }
  end

  # Compatibility
  def get_link(obj, tag) do
    res = Enum.filter_map(
      obj.links,
      fn({{b,k},t}) -> t == tag end,
      fn({{b,k},_t}) -> {b,k} end)
    case res do
      [] -> nil
      v -> v
    end
  end

  # Compatibility
  def get_all_links(obj) do
    MapSet.to_list(obj.links)
  end

  # Compatibility
  def delete_link(obj, tag) do
    links = Enum.filter_map(
      obj.links,
      fn({{b,k},t}) -> t != tag end,
      fn({{b,k},t}) -> {{b,k},t} end)

    %__MODULE__{
      obj | links: links
    }
  end

  # Compatibility
  def delete_all_links(obj) do
    %__MODULE__{
      obj | links: MapSet.new()
    }
  end

  # Compatibility
  def put_link(obj, tag, bucket, key) do
    %__MODULE__{
      obj | links: MapSet.put(obj.links, {{bucket, key}, tag})
    }
  end

  defp md_get(md, key) do
    case :dict.find(key, md) do
      :error -> nil
      {:ok, :undefined} -> nil
      {:ok, v} -> v
    end
  end

  defp from_md_dict(md) do
    %__MODULE__{
      content_type: md_get(md, @md_ctype),
      charset: md_get(md, @md_charset),
      content_encoding: md_get(md, @md_encoding),
      vtag: md_get(md, @md_vtag),
      links: to_mapset(md_get(md, @md_links)),
      last_modified: md_get(md, @md_lastmod),
      metadata: to_map(md_get(md, @md_usermeta)),
      indexes: to_map(md_get(md, @md_index)),
      deleted: md_get(md, @md_deleted)
    }
  end

  defp to_map(nil) do
    %{}
  end
  defp to_map(:undefined) do
    %{}
  end
  defp to_map(v) when is_list(v) do
    Map.new(v)
  end
  defp to_map(v) do
    v
  end

  defp to_mapset(nil) do
    MapSet.new()
  end
  defp to_mapset(:undefined) do
    MapSet.new()
  end
  defp to_mapset(v) when is_list(v) do
    MapSet.new(v)
  end
  defp to_mapset(v) do
    v
  end

  defp md_store(d, k, v) do
    :dict.store(k, v, d)
  end

  defp to_md_dict(obj) do
    :dict.new()
    |> md_store(@md_ctype, to_undefined(obj.content_type))
    |> md_store(@md_charset, to_undefined(obj.charset))
    |> md_store(@md_encoding, to_undefined(obj.content_encoding))
    |> md_store(@md_vtag, to_undefined(obj.vtag))
    |> md_store(@md_links, MapSet.to_list(obj.links))
    |> md_store(@md_lastmod, to_undefined(obj.last_modified))
    |> md_store(@md_usermeta, Map.to_list(to_map(obj.metadata)))
    |> md_store(@md_index, Map.to_list(to_map(obj.indexes)))
    |> md_store(@md_deleted, obj.deleted)
  end

  defp fix_bucket(%__MODULE__{type: nil, bucket: {t, b}}=obj) do
    %{obj | type: t, bucket: b}
  end
  defp fix_bucket(%__MODULE__{type: nil}=obj) do
    %{obj | type: "default"}
  end
  defp fix_bucket(%__MODULE__{}=obj) do
    obj
  end

  defp to_undefined(nil) do
    :undefined
  end
  defp to_undefined(v) do
    v
  end
end

# def from_robj(robj) do
#   data =
#     try do
#       :riakc_obj.get_update_value(robj)
#     catch
#       :no_value -> nil
#       e -> raise e
#     end
#   %Riak.Object{bucket: to_nil(:riakc_obj.bucket(robj)),
#                type: to_nil(:riakc_obj.bucket_type(robj)),
#                key: to_nil(:riakc_obj.key(robj)),
#                data: to_nil(data),
#                metadata: to_nil(:riakc_obj.get_update_metadata(robj)),
#                vclock: to_nil(:riakc_obj.vclock(robj)),
#                content_type: to_nil(:riakc_obj.get_update_content_type(robj))}
# end

# def to_robj(obj) do
#   type = to_undefined(obj.type)
#   bucket = to_bucket(obj.bucket)
#   typed_bucket =
#     case {type, bucket} do
#       {:undefined, b} -> b;
#       {t, {_, b}} -> {t, b};
#       {t, b} -> {t, b};
#     end
#   robj = :riakc_obj.new(
#     typed_bucket,
#     to_undefined(obj.key),
#     to_undefined(obj.data),
#     to_undefined(obj.content_type))
#   robj =
#     case to_undefined(obj.vclock) do
#       :undefined -> robj;
#       v -> :riakc_obj.set_vclock(robj, v)
#     end
#   robj =
#     case to_undefined(obj.metadata) do
#       :undefined -> robj;
#       m -> :riakc_obj.update_metadata(robj, m)
#     end

#   robj
# end

# defp to_nil(:undefined) do
#   nil
# end
# defp to_nil(v) do
#   v
# end

# defp to_bucket({nil, b}) do
#   to_undefined(b)
# end
# defp to_bucket({:undefined, b}) do
#   to_undefined(b)
# end
# defp to_bucket(b) do
#   to_undefined(b)
# end
