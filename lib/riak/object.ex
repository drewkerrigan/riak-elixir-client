defmodule Riak.Object do
  @moduledoc """
  The Data wrapper makes it convenient to work with Riak data in Elixir
  """

  @doc """
  Struct representing a Riak Object. Attributes:
  * `type`: String; Bucket Type with a unique name within the cluster namespace
  * `bucket`: String; Bucket with a unique name within the bucket type namespace
  * `key`: String; Not required; Key with a unique name within the bucket namespace
  * `data`: Any; Value to be stored under the key
  * `metadata`: Orddict; User specified metadata
  * `vclock`: String; Dotted Version Vector / Causal Context for object
  * `content_type`: String; Content Type for object
  """
  defstruct [bucket: nil, type: nil, key: :undefined, data: nil, metadata: nil, vclock: nil, content_type: "application/json"]

  @doc """
  Get all metadata entries
  """
  def get_metadata(obj, key) do
    case :riakc_obj.get_user_metadata_entry(obj.metadata, key) do
      :notfound -> nil
      val -> val
    end
  end

  def get_all_metadata(obj), do: :riakc_obj.get_user_metadata_entries(obj.metadata)

  def delete_metadata(obj, key) do
    %{obj | metadata: :riakc_obj.delete_user_metadata_entry(obj.metadata, key)}
  end

  def delete_all_metadata(obj) do
    %{obj | metadata: :riakc_obj.clear_user_metadata_entries(obj.metadata)}
  end

  def put_metadata(obj, {key, value}) do
    %{obj | metadata: :riakc_obj.set_user_metadata_entry(obj.metadata, {key, value})}
  end

  # Secondary Index
  def index_id({:binary_index, name}), do: "#{name}_bin"
  def index_id({:integer_index, name}), do: "#{name}_int"

  def get_index(obj, {type, name}) do
    case :riakc_obj.get_secondary_index(obj.metadata, {type, name}) do
      :notfound -> nil
      val -> val
    end
  end

  def get_all_indexes(obj) do :riakc_obj.get_secondary_indexes(obj.metadata) end

  def delete_index(obj, {type, name}) do
    %{obj | metadata: :riakc_obj.delete_secondary_index(obj.metadata, {type, name})}
  end

  def delete_all_indexes(obj) do
    %{obj | metadata: :riakc_obj.clear_secondary_indexes(obj.metadata)}
  end

  def put_index(obj, {type, name}, values) do
    %{obj | metadata: :riakc_obj.add_secondary_index(obj.metadata, [{{type, name}, values}])}
  end

  # Links
  def get_link(obj, tag) do
    case :riakc_obj.get_links(obj.metadata, tag) do
      :notfound -> nil
      val -> val
    end
  end

  def get_all_links(obj) do
    :riakc_obj.get_all_links(obj.metadata)
  end

  def delete_link(obj, tag) do
    %{obj | metadata: :riakc_obj.delete_links(obj.metadata, tag)}
  end
  def delete_all_links(obj) do
    %{obj | metadata: :riakc_obj.clear_links(obj.metadata)}
  end

  def put_link(obj, tag, bucket, key) do
    %{obj | metadata: :riakc_obj.add_link(obj.metadata, [{tag, [{bucket,key}]}])}
  end

  def from_robj(robj) do
    %Riak.Object{bucket: :riakc_obj.bucket(robj),
                 type: :riakc_obj.bucket_type(robj),
                 key: :riakc_obj.key(robj),
                 data: :riakc_obj.get_update_value(robj),
                 metadata: :riakc_obj.get_update_metadata(robj),
                 vclock: :riakc_obj.vclock(robj),
                 content_type: :riakc_obj.get_update_content_type(robj)}
  end

  def to_robj(obj) do
    robj = :riakc_obj.new(obj.bucket,
                          obj.key,
                          obj.data,
                          obj.content_type)

    if obj.vclock, do: robj = :riakc_obj.set_vclock(robj, obj.vclock)
    if obj.metadata, do: robj = :riakc_obj.update_metadata(robj, obj.metadata)

    robj
  end

  def create, do: %Riak.Object{}

  def create(args) do
    obj = struct(Riak.Object, args)
    from_robj(to_robj(obj)) # FIXME
  end

end
