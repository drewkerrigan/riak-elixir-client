defmodule Riak.Object do
  @moduledoc """
  The Data wrapper makes it convenient to work with Riak data in Elixir
  """
  defmacro __using__(_opts) do
    quote do
      # User Metadata
      def get_metadata(obj, key) do
        case :riakc_obj.get_user_metadata_entry(obj.metadata, key) do
          :notfound -> nil
          val -> val
        end
      end

      def get_all_metadata(obj), do: :riakc_obj.get_user_metadata_entries(obj.metadata)

      def delete_metadata(obj, key) do
        obj.metadata(:riakc_obj.delete_user_metadata_entry(obj.metadata, key))
      end

      def delete_all_metadata(obj) do
        obj.metadata(:riakc_obj.clear_user_metadata_entries(obj.metadata))
      end

      def put_metadata(obj, {key, value}) do
        obj.metadata(:riakc_obj.set_user_metadata_entry(obj.metadata, {key, value}))
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
        obj.metadata(:riakc_obj.delete_secondary_index(obj.metadata, {type, name}))
      end

      def delete_all_indexes(obj) do
        obj.metadata(:riakc_obj.clear_secondary_indexes(obj.metadata))
      end

      def put_index(obj, {type, name}, values) do
        obj.metadata(:riakc_obj.add_secondary_index(obj.metadata, [{{type, name}, values}]))
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
        obj.metadata(:riakc_obj.delete_links(obj.metadata, tag))
      end
      def delete_all_links(obj) do
        obj.metadata(:riakc_obj.clear_links(obj.metadata))
      end

      def put_link(obj, tag, bucket, key) do
        obj.metadata(:riakc_obj.add_link(obj.metadata, [{tag, [{bucket,key}]}]))
      end
    end
  end
end