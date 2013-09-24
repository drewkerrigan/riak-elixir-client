defmodule Riak.Client do
	use GenServer.Behaviour

	def start_link() do
		:gen_server.start_link({ :local, :riak }, __MODULE__, nil, [])
	end

	def init() do
		{ :ok, nil }
	end

	defmacro __using__(_opts) do
	
		quote do
			# Client level functions
			def configure(opts) do :gen_server.call(:riak, {:configure, Keyword.fetch!(opts, :host), Keyword.fetch!(opts, :port)}) end
			def ping() do :gen_server.call(:riak, {:ping}) end
			def put(obj) do :gen_server.call(:riak, {:store, obj}) end
			def find(bucket, key) do :gen_server.call(:riak, {:fetch, bucket, key}) end
			def resolve(bucket, key, index) do :gen_server.call(:riak, {:resolve, bucket, key, index}) end
			def delete(bucket, key) do :gen_server.call(:riak, {:delete, bucket, key}) end
			def delete(obj) do :gen_server.call(:riak, {:delete, obj.bucket, obj.key}) end

			# Riak modules and functions
			defmodule Bucket do
				def list() do :gen_server.call(:riak, {:list_buckets}) end
				def list(timeout) do :gen_server.call(:riak, {:list_buckets, timeout}) end
				def keys(bucket) do :gen_server.call(:riak, {:list_keys, bucket}) end
				def keys(bucket, timeout) do :gen_server.call(:riak, {:list_keys, bucket, timeout}) end
				def get(bucket) do :gen_server.call(:riak, {:props, bucket}) end
				#Possible Props: [n_val: 3, allow_mult: false, last_write_wins: false, basic_quorum: false, notfound_ok: true, precommit: [], postcommit: [], pr: 0, r: :quorum, w: :quorum, pw: 0, dw: :quorum, rw: :quorum]}
				def put(bucket, props) do :gen_server.call(:riak, {:set_props, bucket, props}) end
				def put(bucket, type, props) do :gen_server.call(:riak, {:set_props, bucket, type, props}) end
				def reset(bucket) do :gen_server.call(:riak, {:reset, bucket}) end

				defmodule Type do
					def get(type) do :gen_server.call(:riak, {:get_type, type}) end
					def put(type, props) do :gen_server.call(:riak, {:set_type, type, props}) end
					def reset(type) do :gen_server.call(:riak, {:reset_type, type}) end
				end
			end

			defmodule Index do
				def query(bucket, {type, name}, key, opts) do 
					case :gen_server.call(:riak, {:index_eq_query, bucket, {type, name}, key, opts}) do
						{:ok, {:index_results_v1, keys, terms, continuation}} -> {keys, terms, continuation}
						res -> res
					end
				end
				def query(bucket, {type, name}, startkey, endkey, opts) do
					case :gen_server.call(:riak, {:index_range_query, bucket, {type, name}, startkey, endkey, opts}) do
						{:ok, {:index_results_v1, keys, terms, continuation}} -> {keys, terms, continuation}
						res -> res
					end
				end
			end

			defmodule Mapred do
				def query(inputs, query) do :gen_server.call(:riak, {:mapred_query, inputs, query}) end
				def query(inputs, query, timeout) do :gen_server.call(:riak, {:mapred_query, inputs, query, timeout}) end
				
				defmodule Bucket do
					def query(bucket, query) do :gen_server.call(:riak, {:mapred_query_bucket, bucket, query}) end
					def query(bucket, query, timeout) do :gen_server.call(:riak, {:mapred_query_bucket, bucket, query, timeout}) end
				end
			end

			defmodule Search do
				def query(bucket, query, options) do :gen_server.call(:riak, {:search_query, bucket, query, options}) end
				def query(bucket, query, options, timeout) do :gen_server.call(:riak, {:search_query, bucket, query, options, timeout}) end
				
				defmodule Index do
					def list() do :gen_server.call(:riak, {:search_list_indexes}) end
					def put(bucket) do :gen_server.call(:riak, {:search_create_index, bucket}) end
					def get(bucket) do :gen_server.call(:riak, {:search_get_index, bucket}) end
					def delete(bucket) do :gen_server.call(:riak, {:search_delete_index, bucket}) end
				end

				defmodule Schema do
					def get(bucket) do :gen_server.call(:riak, {:search_get_schema, bucket}) end
					def create(bucket, content) do :gen_server.call(:riak, {:search_create_schema, bucket, content}) end
				end
			end

			defmodule Counter do
				def enable(bucket) do Bucket.put "#{bucket}-counter", [{:allow_mult, true}] end
				def increment(bucket, name, amount) do :gen_server.call(:riak, {:counter_incr, "#{bucket}-counter", name, amount}) end
				def value(bucket, name) do 
					case :gen_server.call(:riak, {:counter_val, "#{bucket}-counter", name}) do
						{:ok, val} -> val
						val -> val
					end
				end
			end
		end
	end

	def build_sibling_list([{_md, val}|t], final_list) do
		build_sibling_list(t,[val|final_list])
	end
	def build_sibling_list([], final_list) do final_list end
	

	# Start Link to Riak
	def handle_call({ :configure, host, port }, _from, _state) do
    	{:ok, pid} = :riakc_pb_socket.start_link(host, port)
		new_state = Riak.State.new(socket_pid: pid)
		{ :reply, {:ok, pid}, new_state }
  	end

	# Ping Riak
	def handle_call({ :ping }, _from, state) do
  		{ :reply, :riakc_pb_socket.ping(state.socket_pid), state }
	end

	# Store a Riak Object
	def handle_call({:store, obj }, _from, state) do
		case :riakc_pb_socket.put(state.socket_pid, obj.to_robj()) do
			{:ok, new_object} ->
				{ :reply, obj.key(:riakc_obj.key(new_object)), state }
			:ok -> 
				{ :reply, obj, state }
			_ ->
				{ :reply, nil, state }
		end
	end

	# Fetch a Riak Object
	def handle_call({:fetch, bucket, key }, _from, state) do
		case :riakc_pb_socket.get(state.socket_pid, bucket, key) do
			{:ok, object} ->
				if :riakc_obj.value_count(object) > 1 do
					{ :reply, build_sibling_list(:riakc_obj.get_contents(object),[]), state }
				else
					{ :reply, RObj.from_robj(object), state }
				end
			_ -> { :reply, nil, state }
		end
	end

	# Resolve a Riak Object
	def handle_call({:resolve, bucket, key, index }, _from, state) do
		case :riakc_pb_socket.get(state.socket_pid, bucket, key) do
			{:ok, object} ->
				new_object = :riakc_obj.select_sibling(index, object)
				{ :reply, :riakc_pb_socket.put(state.socket_pid, new_object), state }
			_ -> { :reply, nil, state }
		end
	end

	# Delete a Riak Object
	def handle_call({:delete, bucket, key }, _from, state) do
		{ :reply, :riakc_pb_socket.delete(state.socket_pid, bucket, key), state }
	end

	def handle_call({:list_buckets, timeout}, _from, state) do
		{ :reply, :riakc_pb_socket.list_buckets(state.socket_pid, timeout), state}
	end
	def handle_call({:list_buckets}, _from, state) do
		{ :reply, :riakc_pb_socket.list_buckets(state.socket_pid), state}
	end

	def handle_call({:list_keys, bucket, timeout}, _from, state) do
		{ :reply, :riakc_pb_socket.list_keys(state.socket_pid, bucket, timeout), state}
	end
	def handle_call({:list_keys, bucket}, _from, state) do
		{ :reply, :riakc_pb_socket.list_keys(state.socket_pid, bucket), state}
	end

	def handle_call({:props, bucket}, _from, state) do
		{ :reply, :riakc_pb_socket.get_bucket(state.socket_pid, bucket), state}
	end

	def handle_call({:set_props, bucket, props}, _from, state) do
		{ :reply, :riakc_pb_socket.set_bucket(state.socket_pid, bucket, props), state}
	end

	def handle_call({:set_props, bucket, type, props}, _from, state) do
		{ :reply, :riakc_pb_socket.set_bucket(state.socket_pid, {type, bucket}, props), state}
	end

	def handle_call({:reset, bucket}, _from, state) do
		{ :reply, :riakc_pb_socket.reset_bucket(state.socket_pid, bucket), state}
	end

	def handle_call({:get_type, type}, _from, state) do
		{ :reply, :riakc_pb_socket.get_bucket_type(state.socket_pid, type), state}
	end

	def handle_call({:set_type, type, props}, _from, state) do
		{ :reply, :riakc_pb_socket.set_bucket_type(state.socket_pid, type, props), state}
	end
		
	def handle_call({:reset_type, type}, _from, state) do
		{ :reply, :riakc_pb_socket.reset_bucket_type(state.socket_pid, type), state}
	end

	def handle_call({:mapred_query, inputs, query}, _from, state) do
		{ :reply, :riakc_pb_socket.mapred(state.socket_pid, inputs, query), state}
	end
	def handle_call({:mapred_query, inputs, query, timeout}, _from, state) do
		{ :reply, :riakc_pb_socket.mapred(state.socket_pid, inputs, query, timeout), state}
	end

	def handle_call({:mapred_query_bucket, bucket, query}, _from, state) do
		{ :reply, :riakc_pb_socket.mapred_bucket(state.socket_pid, bucket, query), state}
	end
	def handle_call({:mapred_query_bucket, bucket, query, timeout}, _from, state) do
		{ :reply, :riakc_pb_socket.mapred_bucket(state.socket_pid, bucket, query, timeout), state}
	end

	def handle_call({:index_eq_query, bucket, {type, name}, key, opts}, _from, state) do
		{:ok, name} = String.to_char_list(name)
		{ :reply, :riakc_pb_socket.get_index_eq(state.socket_pid, bucket, {type, name}, key, opts), state}
	end
	def handle_call({:index_range_query, bucket, {type, name}, startkey, endkey, opts}, _from, state) do
		{:ok, name} = String.to_char_list(name)
		{ :reply, :riakc_pb_socket.get_index_range(state.socket_pid, bucket, {type, name}, startkey, endkey, opts), state}
	end
	
	def handle_call({:search_list_indexes}, _from, state) do
		{ :reply, :riakc_pb_socket.list_search_indexes(state.socket_pid), state}
	end

	def handle_call({:search_create_index, index}, _from, state) do
		{ :reply, :riakc_pb_socket.create_search_index(state.socket_pid, index), state}
	end

	def handle_call({:search_get_index, index}, _from, state) do
		{ :reply, :riakc_pb_socket.get_search_index(state.socket_pid, index), state}
	end

	def handle_call({:search_delete_index, index}, _from, state) do
		{ :reply, :riakc_pb_socket.delete_search_index(state.socket_pid, index), state}
	end

	def handle_call({:search_get_schema, name}, _from, state) do
		{ :reply, :riakc_pb_socket.get_search_schema(state.socket_pid, name), state}
	end

	def handle_call({:search_create_schema, name, content}, _from, state) do
		{ :reply, :riakc_pb_socket.create_search_schema(state.socket_pid, name, content), state}
	end

	def handle_call({:search_query, index, query, options}, _from, state) do
		{ :reply, :riakc_pb_socket.search(state.socket_pid, index, query, options), state}
	end
	def handle_call({:search_query, index, query, options, timeout}, _from, state) do
		{ :reply, :riakc_pb_socket.search(state.socket_pid, index, query, options, timeout), state}
	end

	def handle_call({:counter_incr, bucket, key, amount}, _from, state) do
		{ :reply, :riakc_pb_socket.counter_incr(state.socket_pid, bucket, key, amount), state}
	end

	def handle_call({:counter_val, bucket, key}, _from, state) do
		{ :reply, :riakc_pb_socket.counter_val(state.socket_pid, bucket, key), state}
	end
end