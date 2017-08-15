defmodule RiakTest do
  use Riak.Case

  @moduletag :riak1

  test "put", context do
    pid = context[:pid]
    key = Riak.Helper.random_key

    o =  Riak.Object.create(bucket: "user", key: key, data: "Drew Kerrigan")

    assert Riak.put(pid, o) == o
  end

  test "find", context do
    pid = context[:pid]
    key = Riak.Helper.random_key

    data = "Drew Kerrigan"
    o =  Riak.Object.create(bucket: "user", key: key, data: data)
    Riak.put(pid, o)

    assert Riak.find(pid, "user", key).data == o.data
  end

  # curl -XDELETE http://localhost:8098/types/spot/buckets/active/keys/EURUSD
  @tag :skip
  test "find with deleted", context do

    pid = context[:pid]
    key = Riak.Helper.random_key
    data = "Drew_Kerrigan"

    target = "http://localhost:8098/types/user_types/buckets/user/keys"
    System.cmd("curl", ~w[-s -XPUT #{target}/#{key} -d {"value_s":"#{data}_1"} -H Content-Type:application/json])
    System.cmd("curl", ~w[-s -XDELETE #{target}/#{key}])
    System.cmd("curl", ~w[-s -XPUT #{target}/#{key} -d {"value_s":"#{data}_2"} -H Content-Type:application/json])

    assert Riak.find(pid, {"user_types", "user"}, key).data == ~s[{"value_s":"#{data}_2"}]
  end

  test "delete", context do
    pid = context[:pid]
    key = Riak.Helper.random_key

    o =  Riak.Object.create(bucket: "user", key: key, data: "Drew Kerrigan")
    Riak.put(pid, o)

    assert Riak.delete(pid, o) == :ok
  end

  test "crud operations and siblings", context do
    pid = context[:pid]
    key = Riak.Helper.random_key

    o =  Riak.Object.create(bucket: "user", key: key, data: "Drew Kerrigan")
    u = Riak.put(pid, o)

    assert u != nil

    assert :ok == Riak.delete pid, "user", u.key

    u = Riak.Object.create(bucket: "user", data: "Drew Kerrigan")
    assert u.key == nil
    u = Riak.put pid, u
    assert u.key != nil

    # Get the object again so we don't create a sibling
    u = Riak.find pid, "user", u.key

    o = %{u | data: "Something Else"}
    u = Riak.put pid, o

    unewdata = Riak.find pid, "user", u.key

    assert unewdata.data == "Something Else"

    assert :ok == Riak.delete pid, "user", u.key
    assert :ok == Riak.delete pid, "user", key

    assert nil == Riak.find pid, "user", key
  end

  # test "create siblings", context do
  #   pid = context[:pid]
  #   key = Riak.Helper.random_key

  #   o = Riak.Object.create(type: "siblings", bucket: "user", key: key, data: "Drew Kerrigan")
  #   Riak.put(pid, o)
  #   Riak.put(pid, o)
  #   u = Riak.find(pid, {"siblings", "user"}, key)
  #   u = case u do
  #         nil -> Riak.find(pid, {"siblings", "user"}, key)
  #         u -> u
  #       end
  #   assert u != nil
  #   assert is_list(u)
  #   Riak.resolve(pid, {"siblings", "user"}, key, Riak.Helper.index_of("Drew Kerrigan", u))
  #   u = Riak.find(pid, {"siblings", "user"}, key)
  #   assert u != nil
  #   assert u.data == "Drew Kerrigan"
  #   assert :ok == Riak.delete pid, u
  # end

  test "user metadata", context do
    pid = context[:pid]
    key = Riak.Helper.random_key

    mdtest = Riak.Object.create(bucket: "user", key: key, data: "Drew Kerrigan")
      |> Riak.Object.put_metadata({"my_key", "my_value"})
      |> Riak.Object.put_metadata({"my_key2", "my_value2"})

      mdtest = Riak.put(pid, mdtest)
        |> Riak.Object.get_metadata("my_key")

    assert mdtest == "my_value"

    u = Riak.find pid, "user", key

    mdtest2 = u
      |> Riak.Object.get_metadata("my_key2")

    assert mdtest2 == "my_value2"

    mdtest3 = u
      |> Riak.Object.get_all_metadata()
      |> is_list

    assert mdtest3

    u = Riak.Object.delete_metadata(u, "my_key")

    assert nil == Riak.Object.get_metadata(u, "my_key")
    assert "my_value2" == Riak.Object.get_metadata(u, "my_key2")

    u = Riak.Object.delete_all_metadata(u)

    assert nil == Riak.Object.get_metadata(u, "my_key2")
    assert [] == Riak.Object.get_all_metadata(u)
  end

  test "secondary indexes", context do
    pid = context[:pid]
    key = Riak.Helper.random_key

    o = Riak.Object.create(bucket: "user", key: key, data: "Drew Kerrigan")
      |> Riak.Object.put_index({:binary_index, "first_name"}, ["Drew"])
      |> Riak.Object.put_index({:binary_index, "last_name"}, ["Kerrigan"])
    Riak.put(pid, o)

    assert Riak.Object.get_index(o, {:binary_index, "first_name"}) == ["Drew"]

    case Riak.Index.query(pid, "user", {:binary_index, "first_name"}, "Drew", []) do
      {:error, "{error,{indexes_not_supported,riak_kv_bitcask_backend}}"} -> :ok
      {keys, terms, continuation} ->
        assert is_list(keys)
        assert terms == :undefined
        assert continuation == :undefined
        {keys, terms, continuation} = Riak.Index.query(pid, "user", {:binary_index, "last_name"}, "Kerrigam", "Kerrigao", [])
        assert is_list(keys)
        assert terms == :undefined
        assert continuation == :undefined
    end

    o = Riak.Object.delete_index(o, {:binary_index, "first_name"})
    Riak.put(pid, o)

    assert Riak.Object.get_index(o, {:binary_index, "first_name"}) == nil

    assert is_list(Riak.Object.get_all_indexes(o))

    indextest = o |> Riak.Object.delete_all_indexes
      |> Riak.Object.get_all_indexes

    assert indextest == []
  end

  test "links", context do
    pid = context[:pid]

    o1 =Riak.Object.create(bucket: "user", key: "drew1", data: "Drew1 Kerrigan")
    Riak.put(pid, o1)
    o2 = Riak.Object.create(bucket: "user", key: "drew2", data: "Drew2 Kerrigan")
    Riak.put(pid, o2)

    key = Riak.Helper.random_key

    o = Riak.Object.create(bucket: "user", key: key, data: "Drew Kerrigan")
      |> Riak.Object.put_link("my_tag", "user", "drew1")
      |> Riak.Object.put_link("my_tag", "user", "drew2")
    Riak.put(pid, o)

    assert Riak.Object.get_link(o, "my_tag") == [{"user", "drew1"}, {"user", "drew2"}]

    assert Riak.Object.delete_link(o, "my_tag") |> Riak.Object.get_link("my_tag") == nil

    # Get the object again so we don't create a sibling
    o = Riak.find pid, "user", key

    o |> Riak.Object.put_link("my_tag", "user", "drew1")
      |> Riak.Object.put_link("my_tag", "user", "drew2")
    Riak.put(pid, o)

    assert Riak.Object.get_link(o, "my_tag") == [{"user", "drew1"}, {"user", "drew2"}]

    assert is_list(Riak.Object.get_all_links(o))
    assert Riak.Object.delete_all_links(o) |> Riak.Object.get_all_links == []
  end

  test "ping", context do
    assert Riak.ping(context[:pid]) == :pong
  end

  test "siblings", context do
    pid = context[:pid]
    assert :ok == Riak.Bucket.put pid, "user", [{:allow_mult, true}]

    key = Riak.Helper.random_key

    o1 = Riak.Object.create(bucket: "user", key: key, data: "Drew1 Kerrigan")
    Riak.put(pid, o1)
    o2 = Riak.Object.create(bucket: "user", key: key, data: "Drew2 Kerrigan")
    Riak.put(pid, o2)

    u = Riak.find pid, "user", key

    assert is_list(u)

    [h|_t] = u

    assert :ok == Riak.resolve(pid, "user", key, 2)

    u = Riak.find pid, "user", key

    assert u.data == h

    assert :ok == Riak.Bucket.reset pid, "user"
  end
end
