defmodule Riak.Object do
	defmacro __using__(_opts) do
		quote do
			def from_robj(robj) do
				RObj.new(
					bucket: :riakc_obj.bucket(robj),
					key: :riakc_obj.key(robj),
					data: :riakc_obj.get_update_value(robj),
					metadata: :riakc_obj.get_update_metadata(robj),
					vclock: :riakc_obj.vclock(robj),
					content_type: :riakc_obj.get_update_content_type(robj))
			end

			def to_robj(obj) do
				unless obj.key do obj = obj.key(:undefined) end

				robj = :riakc_obj.new(
					obj.bucket, 
					obj.key, 
					obj.data,
					obj.content_type)

				if obj.vclock do robj = :riakc_obj.set_vclock(robj, obj.vclock) end
				if obj.metadata do robj = :riakc_obj.update_metadata(robj, obj.metadata) end

				robj
			end
			
			def create() do
				RObj.new()
			end
			def create(args) do
				obj = RObj.new(args)
				from_robj(to_robj(obj))
			end

			# User Metadata
			def get_metadata(obj, key) do 
				case :riakc_obj.get_user_metadata_entry(obj.metadata, key) do
					:notfound -> nil
					val -> val
				end
			end
			def get_all_metadata(obj) do :riakc_obj.get_user_metadata_entries(obj.metadata) end
			def delete_all_metadata(obj) do obj.metadata(:riakc_obj.clear_user_metadata_entries(obj.metadata)) end
			def delete_metadata(obj, key) do obj.metadata(:riakc_obj.delete_user_metadata_entry(obj.metadata, key)) end
			def put_metadata(obj, {key, value}) do obj.metadata(:riakc_obj.set_user_metadata_entry(obj.metadata, {key, value})) end

			# Secondary Index
			def index_id({:binary_index, name}) do "#{name}_bin" end
			def index_id({:integer_index, name}) do "#{name}_int" end
			def get_index(obj, {type, name}) do
				case :riakc_obj.get_secondary_index(obj.metadata, {type, name}) do
					:notfound -> nil
					val -> val
				end
			end
			def get_all_indexes(obj) do :riakc_obj.get_secondary_indexes(obj.metadata) end
			def delete_all_indexes(obj) do obj.metadata(:riakc_obj.clear_secondary_indexes(obj.metadata)) end
			def delete_index(obj, {type, name}) do obj.metadata(:riakc_obj.delete_secondary_index(obj.metadata, {type, name})) end
			def put_index(obj, {type, name}, values) do obj.metadata(:riakc_obj.add_secondary_index(obj.metadata, [{{type, name}, values}])) end

			# Links
			def get_link(obj, tag) do
				case :riakc_obj.get_links(obj.metadata, tag) do
					:notfound -> nil
					val -> val
				end
			end
			def get_all_links(obj) do :riakc_obj.get_all_links(obj.metadata) end
			def delete_all_links(obj) do obj.metadata(:riakc_obj.clear_links(obj.metadata)) end
			def delete_link(obj, tag) do obj.metadata(:riakc_obj.delete_links(obj.metadata, tag)) end
			def put_link(obj, tag, bucket, key) do obj.metadata(:riakc_obj.add_link(obj.metadata, [{tag, [{bucket,key}]}])) end
		end
	end
end

defrecord RObj, [bucket: nil, key: nil, data: nil, metadata: nil, vclock: nil, content_type: "application/json"] do
	use Riak.Object
end