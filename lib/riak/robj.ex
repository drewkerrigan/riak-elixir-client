defmodule RObj do
  require Record
  Record.defrecord :robj, RObj, [bucket: nil, key: nil, data: nil, metadata: nil, vclock: nil, content_type: "application/json"]
  use Riak.Object

  def data(new_data, obj) do
    robj(obj, data: new_data)
  end

  def data(obj) do
    robj(obj, :data)
  end

  def metadata(new_metadata, obj) do
    robj(obj, metadata: new_metadata)
  end

  def metadata(obj) do
    robj(obj, :metadata)
  end

  def key(new_key, obj) do
    robj(obj, key: new_key)
  end

  def key(obj) do
    robj(obj, :key)
  end

  def from_robj(robj) do
    robj(
      bucket: :riakc_obj.bucket(robj),
      key: :riakc_obj.key(robj),
      data: :riakc_obj.get_update_value(robj),
      metadata: :riakc_obj.get_update_metadata(robj),
      vclock: :riakc_obj.vclock(robj),
      content_type: :riakc_obj.get_update_content_type(robj))
  end

  def to_robj(obj) do
    unless robj(obj, :key), do: obj = robj(obj, key: :undefined)

    myrobj = :riakc_obj.new(
      robj(obj, :bucket), 
      robj(obj, :key), 
      robj(obj, :data),
      robj(obj, :content_type)
    )

    if robj(obj, :vclock), do: myrobj = :riakc_obj.set_vclock(myrobj, robj(obj, :vclock))
    if robj(obj, :metadata), do: myrobj = :riakc_obj.update_metadata(myrobj, robj(obj, :metadata))

    myrobj
  end
  
  def create(), do: robj()

  def create(args) do
    obj = robj()
    if args[:bucket], do: obj = robj(obj, bucket: args[:bucket])
    if args[:key], do: obj = robj(obj, key: args[:key])
    if args[:data], do: obj = robj(obj, data: args[:data])
    if args[:metadata], do: obj = robj(obj, metadata: args[:metadata])
    if args[:vclock], do: obj = robj(obj, vclock: args[:vclock])
    if args[:content_type], do: obj = robj(obj, content_type: args[:content_type])
    obj |>
    to_robj |>
    from_robj
  end
end