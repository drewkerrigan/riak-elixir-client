defmodule Db do
	use Riak.Client
end

defmodule RiakTest do
	use ExUnit.Case

	setup do
		Db.configure(host: '127.0.0.1', port: 10017)
		:ok
	end

	test "list bucket" do
		{:ok, buckets} = Db.Bucket.list
		assert(is_list(buckets))
	end

	test "list keys" do
		{:ok, users} = Db.Bucket.keys "user"
		assert(is_list(users))
	end

	test "bucket props" do
		# Currently there seems to be a bug that returns "Creating new atoms from protobuffs message!"
		assert(:ok == Db.Bucket.put "user", [{:notfound_ok, false}])

		{:ok, props} = Db.Bucket.get "user"
		assert(is_list(props))
		assert(props[:notfound_ok] == false)

		assert(:ok == Db.Bucket.reset "user")

		{:ok, props} = Db.Bucket.get "user"
		assert(props[:notfound_ok] == true)
	end

	test "bucket types" do
		assert(:ok == Db.Bucket.Type.put("multi", [{:allow_mult, true}]))
		# Currently there seems to be a bug that returns "Creating new atoms from protobuffs message!"
		{:ok, props} = Db.Bucket.Type.get("multi")
		assert(is_list(props))
		assert(props[:allow_mult] == true)

		assert(:ok == Db.Bucket.Type.reset("multi"))
	end

	test "crud operations" do
		{me, se, mi} = :erlang.now
		key = "#{me}#{se}#{mi}"
		
		u = RObj.create(bucket: "user", key: key, data: "Drew Kerrigan")
			|> Db.put

		assert(u != nil)

		u = RObj.create(bucket: "user", data: "Drew Kerrigan")
		assert(u.key == :undefined)
		u = Db.put u
		assert(u.key != :undefined)

		u = u.data("Something Else")
			|> Db.put

		unewdata = Db.find "user", u.key
		assert(unewdata.data == "Something Else")

		assert(:ok == Db.delete "user", u.key)
		assert(:ok == Db.delete "user", key)

		assert(nil == Db.find "user", key)
	end

	test "user metadata" do
		{me, se, mi} = :erlang.now
		key = "#{me}#{se}#{mi}"
		mdtest = RObj.create(bucket: "user", key: key, data: "Drew Kerrigan")
			|> RObj.put_metadata({"my_key", "my_value"})
			|> RObj.put_metadata({"my_key2", "my_value2"})
			|> Db.put
			|> RObj.get_metadata("my_key")

		assert(mdtest == "my_value")

		u = Db.find "user", key

		mdtest2 = u
			|> RObj.get_metadata("my_key2")

		assert(mdtest2 == "my_value2")

		mdtest3 = u
			|> RObj.get_all_metadata()
			|> is_list

		assert(mdtest3)

		u = RObj.delete_metadata(u, "my_key")
		
		assert(nil == RObj.get_metadata(u, "my_key"))
		assert("my_value2" == RObj.get_metadata(u, "my_key2"))
		
		u = RObj.delete_all_metadata(u)

		assert(nil == RObj.get_metadata(u, "my_key2"))
		assert([] == RObj.get_all_metadata(u))
	end

	test "secondary indexes" do
		{me, se, mi} = :erlang.now
		key = "#{me}#{se}#{mi}"
		u = RObj.create(bucket: "user", key: key, data: "Drew Kerrigan")
			|> RObj.put_index({:binary_index, "first_name"}, ["Drew"])
			|> RObj.put_index({:binary_index, "last_name"}, ["Kerrigan"])
			|> Db.put

		assert(RObj.get_index(u, {:binary_index, "first_name"}) == ["Drew"])

		{keys, terms, continuation} = Db.Index.query("user", {:binary_index, "first_name"}, "Drew", [])
		assert(is_list(keys))
		assert(terms == :undefined)
		assert(continuation == :undefined)
		{keys, terms, continuation} = Db.Index.query("user", {:binary_index, "last_name"}, "Kerrigam", "Kerrigao", [])
		assert(is_list(keys))
		assert(terms == :undefined)
		assert(continuation == :undefined)

		u = RObj.delete_index(u, {:binary_index, "first_name"})
			|> Db.put

		assert(RObj.get_index(u, {:binary_index, "first_name"}) == nil)
		
		assert(is_list(RObj.get_all_indexes(u)))
		
		indextest = u |> RObj.delete_all_indexes()
			|> RObj.get_all_indexes()

		assert(indextest == [])
	end

	test "links" do
		RObj.create(bucket: "user", key: "drew1", data: "Drew1 Kerrigan")
			|> Db.put
		RObj.create(bucket: "user", key: "drew2", data: "Drew2 Kerrigan")
			|> Db.put

		{me, se, mi} = :erlang.now
		key = "#{me}#{se}#{mi}"
		u = RObj.create(bucket: "user", key: key, data: "Drew Kerrigan")
			|> RObj.put_link("my_tag", "user", "drew1")
			|> RObj.put_link("my_tag", "user", "drew2")
			|> Db.put

		assert(RObj.get_link(u, "my_tag") == [{"user", "drew1"}, {"user", "drew2"}])
		
		assert(RObj.delete_link(u, "my_tag") |> RObj.get_link("my_tag") == nil)

		u = RObj.create(bucket: "user", key: key, data: "Drew Kerrigan")
			|> RObj.put_link("my_tag", "user", "drew1")
			|> RObj.put_link("my_tag", "user", "drew2")
			|> Db.put

		assert(RObj.get_link(u, "my_tag") == [{"user", "drew1"}, {"user", "drew2"}])

		assert(is_list(RObj.get_all_links(u)))
		assert(RObj.delete_all_links(u) |> RObj.get_all_links() == [])
	end

	test "ping" do
		assert(Db.ping == :pong)
	end

	test "siblings" do
		assert(:ok == Db.Bucket.put "user", [{:allow_mult, true}])

		{me, se, mi} = :erlang.now
		key = "#{me}#{se}#{mi}"

		RObj.create(bucket: "user", key: key, data: "Drew1 Kerrigan")
			|> Db.put
		RObj.create(bucket: "user", key: key, data: "Drew2 Kerrigan")
			|> Db.put

		u = Db.find "user", key

		assert(is_list(u))

		[h|_t] = u

		assert(:ok == Db.resolve("user", key, 2))
		
		u = Db.find "user", key

		assert(u.data == h)

		assert(:ok == Db.Bucket.reset "user")
	end

	test "counters" do
		assert(true)
		# {me, se, mi} = :erlang.now
		# counter_key = "my_counter_#{me}#{se}#{mi}"

		# #Creates bucket called "user_counter"
		# assert(:ok == Db.Counter.enable("user"))
		# assert(:ok == Db.Counter.increment("user", counter_key, 1))
		# assert(:ok == Db.Counter.increment("user", counter_key, 2))
		# assert(:ok == Db.Counter.increment("user", counter_key, 3))

		# assert(6 == Db.Counter.value("user", counter_key))
	end

	#Haven't found a way to make these work yet, use stored code
	test "mapred" do
		assert(true)
		# {me, se, mi} = :erlang.now
		# key = "#{me}#{se}#{mi}"

		# u = RObj.create(bucket: "user", key: key, data: "Drew Kerrigan")
		# 	|> RObj.put_index({:binary_index, "first_name"}, ["Drew"])
		# 	|> RObj.put_index({:binary_index, "last_name"}, ["Kerrigan"])
		# 	|> Db.put

		# {:ok, [{n2, r2}]} = Db.Mapred.query(
		# res = Db.Mapred.query(
		# 	{:index, "user", {:binary_index, 'first_name'}, 'Drev', 'Drex'},
		# 	[{:map, {:qfun, recsize}, :none, :false},
		# 	 {:reduce, {:modfun, :'riak_kv_mapreduce', :'reduce_sum'}, :none, :true}])

		# res = Db.Mapred.query(
		# 	{:index, "user", {:binary_index, "first_name"}, "Drev", "Drex"}, 
		# 	[{:map, {:jsfun, "Riak.mapValues"}, :undefined, :false}])
		# IO.inspect mapredres
		# assert(is_list(mapredres))
	end

	#Haven't had time to test search functionality yet
	test "search" do
		assert(true)

		# {:ok, [[index: "delete_meRJIndex", schema: "_yz_default"], [index: "foobarRJIndex", schema: "_yz_default"], [index: "peopleRJIndex", schema: "_yz_default"], [index: "test_postRJIndex", schema: "_yz_default"], [index: "user", schema: "_yz_default"]]}
		# {:ok, [index: "user", schema: "_yz_default"]}
		# {:ok, {:search_results, [], 0.0, 0}}
		
		# IO.inspect Db.Search.Index.list()
		# IO.inspect Db.Search.Index.get User

		# IO.inspect Db.Search.query User, "first_name_t:*Drew*", []

		#Delete works, but we want it to stick around because there is a delay from the time an index is created to when it can be used, so if search test fails at first, try again
		#IO.inspect Db.Search.Index.put User
		#IO.inspect Db.Search.Index.delete User

		#IO.inspect Db.Search.Schema.get(mod) do :gen_server.call(:elixiak, {:search_get_schema, mod.bucket}) end
		#IO.inspect Db.Search.Schema.create(mod, content) do :gen_server.call(:elixiak, {:search_create_schema, mod.bucket, content}) end
	end
end