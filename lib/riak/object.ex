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
    type: string,
    bucket: string,
    key: string,
    data: binary,
    siblings: list,
    context: binary,
    content_type: string,
    charset: string,
    content_encoding: string,
    vtag: string,
    links: MapSet,
    last_modified: string,
    indexes: map,
    metadata: map,
    deleted: boolean
  }

  defstruct [
    type: nil,
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
    links: MapSet.new,
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

  def md_get(md, key) do
    case :dict.find(key, md) do
      :error -> nil
      {ok, :undefined} -> nil
      {ok, v} -> v
    end
  end

  def from_md_dict(md) do
    %__MODULE__{
      content_type: md_get(md, @md_ctype),
      charset: md_get(md, @md_charset),
      content_encoding: md_get(md, @md_encoding),
      vtag: md_get(md, @md_vtag),
      links: md_get(md, @md_links),
      last_modified: md_get(md, @md_lastmod),
      metadata: md_get(md, @md_usermeta),
      indexes: md_get(md, @md_index),
      deleted: md_get(md, @md_deleted)
    }

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
    %{obj |
      type: type,
      bucket: bucket,
      key: key,
      data: nil,
      context: context,
      siblings: from_record_siblings(rec, [])
    }
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
    {:riakc_obj, {type, bucket}, key, context, [], to_md_dict(obj), obj.data}
  end






  @doc """
  Get all metadata entries
  """
  def get_metadata(obj, key) do
    case :riakc_obj.get_user_metadata_entry(
          to_undefined(obj.metadata), to_undefined(key)) do
      :notfound -> nil
      val -> val
    end
  end

  def get_all_metadata(obj) do
    :riakc_obj.get_user_metadata_entries(
      to_undefined(obj.metadata))
  end

  def delete_metadata(obj, key) do
    %{obj | metadata: :riakc_obj.delete_user_metadata_entry(
         to_undefined(obj.metadata), to_undefined(key))}
  end

  def delete_all_metadata(obj) do
    %{obj | metadata: :riakc_obj.clear_user_metadata_entries(
         to_undefined(obj.metadata))}
  end

  def put_metadata(obj, {key, value}) do
    %{obj | metadata: :riakc_obj.set_user_metadata_entry(
         to_undefined(obj.metadata), {key, value})}
  end

  # Secondary Index
  def index_id({:binary_index, name}), do: "#{name}_bin"
  def index_id({:integer_index, name}), do: "#{name}_int"

  def get_index(obj, {type, name}) do
    case :riakc_obj.get_secondary_index(
          to_undefined(obj.metadata),
          {to_undefined(type), to_undefined(name)}) do
      :notfound -> nil
      val -> val
    end
  end

  def get_all_indexes(obj) do
    :riakc_obj.get_secondary_indexes(to_undefined(obj.metadata))
  end

  def delete_index(obj, {type, name}) do
    %{obj | metadata: :riakc_obj.delete_secondary_index(
         to_undefined(obj.metadata),
         {to_undefined(type), to_undefined(name)})}
  end

  def delete_all_indexes(obj) do
    %{obj | metadata: :riakc_obj.clear_secondary_indexes(
         to_undefined(obj.metadata))}
  end

  def put_index(obj, {type, name}, values) do
    %{obj | metadata: :riakc_obj.add_secondary_index(
         to_undefined(obj.metadata),
         [{{to_undefined(type), to_undefined(name)},
           to_undefined(values)}])}
  end

  # Links
  def get_link(obj, tag) do
    case :riakc_obj.get_links(
          to_undefined(obj.metadata), tag) do
      :notfound -> nil
      val -> val
    end
  end

  def get_all_links(obj) do
    :riakc_obj.get_all_links(
      to_undefined(obj.metadata))
  end

  def delete_link(obj, tag) do
    %{obj | metadata: :riakc_obj.delete_links(
         to_undefined(obj.metadata), tag)}
  end
  def delete_all_links(obj) do
    %{obj | metadata: :riakc_obj.clear_links(
         to_undefined(obj.metadata))}
  end

  def put_link(obj, tag, bucket, key) do
    %{obj | metadata: :riakc_obj.add_link(
         to_undefined(obj.metadata),
         [{tag, [{to_undefined(bucket),to_undefined(key)}]}])}
  end

  def from_robj(robj) do
    data =
      try do
        :riakc_obj.get_update_value(robj)
      catch
        :no_value -> nil
        e -> raise e
      end
    %Riak.Object{bucket: to_nil(:riakc_obj.bucket(robj)),
                 type: to_nil(:riakc_obj.bucket_type(robj)),
                 key: to_nil(:riakc_obj.key(robj)),
                 data: to_nil(data),
                 metadata: to_nil(:riakc_obj.get_update_metadata(robj)),
                 vclock: to_nil(:riakc_obj.vclock(robj)),
                 content_type: to_nil(:riakc_obj.get_update_content_type(robj))}
  end

  def to_robj(obj) do
    type = to_undefined(obj.type)
    bucket = to_bucket(obj.bucket)
    typed_bucket =
      case {type, bucket} do
        {:undefined, b} -> b;
        {t, {_, b}} -> {t, b};
        {t, b} -> {t, b};
      end
    robj = :riakc_obj.new(
      typed_bucket,
      to_undefined(obj.key),
      to_undefined(obj.data),
      to_undefined(obj.content_type))
    robj =
      case to_undefined(obj.vclock) do
        :undefined -> robj;
        v -> :riakc_obj.set_vclock(robj, v)
      end
    robj =
      case to_undefined(obj.metadata) do
        :undefined -> robj;
        m -> :riakc_obj.update_metadata(robj, m)
      end

    robj
  end

  def create(args \\ [bucket: "default"]) do
    obj = struct(Riak.Object, args)
    from_robj(to_robj(obj))
  end

  defp to_undefined(nil) do
    :undefined
  end
  defp to_undefined(v) do
    v
  end

  defp to_nil(:undefined) do
    nil
  end
  defp to_nil(v) do
    v
  end

  defp to_bucket({nil, b}) do
    to_undefined(b)
  end
  defp to_bucket({:undefined, b}) do
    to_undefined(b)
  end
  defp to_bucket(b) do
    to_undefined(b)
  end


end
