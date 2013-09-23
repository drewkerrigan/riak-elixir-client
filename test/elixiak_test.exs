defmodule Db do
	use Elixiak.Database, host: '127.0.0.1', port: 8087
end

defmodule User do
	use Elixiak.Model

	document "user" do
		field :first_name_t, :string
		field :last_name_t, :string
		field :age_i, :integer, default: 18
	end
end

defmodule ElixiakTest do
	use ExUnit.Case

	test "database_functions" do
		{:ok, buckets} = Db.Bucket.list
		assert(is_list(buckets))

		{:ok, users} = Db.Bucket.keys User
		assert(is_list(users))

		# Currently there seems to be a bug that returns "Creating new atoms from protobuffs message!"
		#{:ok, props} = Db.Bucket.get User
		# Possible bucket props:
		#[n_val: 3, allow_mult: false, last_write_wins: false, basic_quorum: false, notfound_ok: true, precommit: [], postcommit: [], pr: 0, r: :quorum, w: :quorum, pw: 0, dw: :quorum, rw: :quorum]}
		Db.Bucket.put User, [{:notfound_ok, true}]
		Db.Bucket.reset User
		Db.Bucket.Type.put("multi", [{:allow_mult, true}])
		# Currently there seems to be a bug that returns "Creating new atoms from protobuffs message!"
		#{:ok, props} = Db.Bucket.Type.get("multi")
		Db.Bucket.Type.reset("multi")

		{me, se, mi} = :erlang.now
		key = "#{me}#{se}#{mi}"
		
		u = User.new(key: key, first_name_t: "Drew", last_name_t: "Kerrigan", age_i: 200)
		u = Db.put u
		u = User.Index.put u, {:binary_index, "first_name_t"}, [u.first_name_t]
		Db.update u
		{:ok, {:index_results_v1, _searchres1, _, _}} = Db.Index.query User, {:binary_index, 'first_name_t'}, "Drew", []
		#assert(List.last(searchres1) == key) list contains?
		{:ok, {:index_results_v1, _searchres2, _, _}} = Db.Index.query User, {:binary_index, 'first_name_t'}, "Drew", "Drew", []
		#assert(List.last(searchres2) == key)

		# TODO: use reduce as well
		{:ok, mapredres} = Db.Mapred.query([{"user", key}], [{:map, {:jsfun, "Riak.mapValuesJson"}, :undefined, false}])
		assert(is_list(mapredres))
		# Syntax error?
		#IO.inspect Db.Mapred.Bucket.query User, [{:map, {:jsfun, "Riak.mapValuesJson"}, :undefined, false}]


		{:ok, [[index: "delete_meRJIndex", schema: "_yz_default"], [index: "foobarRJIndex", schema: "_yz_default"], [index: "peopleRJIndex", schema: "_yz_default"], [index: "test_postRJIndex", schema: "_yz_default"], [index: "user", schema: "_yz_default"]]}
		{:ok, [index: "user", schema: "_yz_default"]}
		{:ok, {:search_results, [], 0.0, 0}}
		
		IO.inspect Db.Search.Index.list()
		IO.inspect Db.Search.Index.get User

		IO.inspect Db.Search.query User, "first_name_t:*Drew*", []
		#Delete works, but we want it to stick around because there is a delay from the time an index is created to when it can be used, so if search test fails at first, try again
		#IO.inspect Db.Search.Index.put User
		#IO.inspect Db.Search.Index.delete User

		#IO.inspect Db.Search.Schema.get(mod) do :gen_server.call(:elixiak, {:search_get_schema, mod.bucket}) end
		#IO.inspect Db.Search.Schema.create(mod, content) do :gen_server.call(:elixiak, {:search_create_schema, mod.bucket, content}) end
	end

	# test "update" do
	# 	u = User.new(key: "drew", first_name_t: "Drew", last_name_t: "Kerrigan", age_i: 200)
	# 	Db.put u

	# 	u2 = Db.find User, "drew"
	# 	assert(u2.last_name_t == "Kerrigan")

	# 	u3 = u2.first_name_t("Harry")
	# 	Db.update u3

	# 	u4 = Db.find User, "drew"
	# 	assert(u4.first_name_t == "Harry")

	# 	Db.delete User, "drew"

	# 	u4 = Db.find User, "drew"
	# 	assert(u4 == nil)
	# end

	# test "save_find_delete" do
	# 	u = User.new(key: "drew", first_name_t: "Drew", last_name_t: "Kerrigan", age_i: 200)
	# 	Db.put u

	# 	u2 = Db.find User, "drew"
	# 	assert(u2.last_name_t == "Kerrigan")

	# 	Db.delete User, "drew"

	# 	u3 = Db.find User, "drew"
	# 	assert(u3 == nil)
	# end

	# test "save_find_delete_nokey" do
	# 	u = User.new(first_name_t: "Drew", last_name_t: "Kerrigan", age_i: 200)
	# 	key = Db.put u

	# 	u2 = Db.find User, key
	# 	assert(u2.last_name_t == "Kerrigan")

	# 	Db.delete User, key

	# 	u3 = Db.find User, key
	# 	assert(u3 == nil)
	# end

	# test "alternate_delete" do
	# 	u = User.new(first_name_t: "Drew", last_name_t: "Kerrigan", age_i: 200)
	# 	key = Db.put u

	# 	u2 = Db.find User, key
	# 	assert(u2.last_name_t == "Kerrigan")

	# 	Db.delete u2

	# 	u3 = Db.find User, key
	# 	assert(u3 == nil)
	# end
end