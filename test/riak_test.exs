defmodule RiakTest do
  use ExUnit.Case

  defmodule RiakClient do
    use Riak

    def conf do
      host = System.get_env("RIAK_HOST") || "127.0.0.1"
      port = System.get_env("RIAK_PORT") || "8087"
      host = to_char_list(host)
      port = elem(Integer.parse(port), 0)
      Riak.configure(host: host, port: port)
    end

  end

  defmodule Struct do
    use Application

    # See http://elixir-lang.org/docs/stable/elixir/Application.html
    # for more information on OTP Applications
    def start(_type, _args) do
      import Supervisor.Spec, warn: false

      children = [worker(RiakClient, [])]

      opts = [strategy: :one_for_one, name: Struct.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end

  # helper for chosing the index of a sibling value list
  def index_of(search, [search|_], index) do
    index
  end
  def index_of(search, [_|rest], index) do
    index_of(search, rest, index+1)
  end
  def index_of(search, haystack) do
    index_of(search, haystack, 1)
  end

  setup do
    Struct.start(:undefined,[])
    :ok
  end

  test "list bucket" do
    {:ok, buckets} = Riak.Bucket.list
    assert(is_list(buckets))
  end

  test "list keys" do
    {:ok, users} = Riak.Bucket.keys "user"
    assert(is_list(users))
  end

  test "bucket props" do
    # Currently there seems to be a bug that returns "Creating new atoms from protobuffs message!"
    assert(:ok == Riak.Bucket.put "user", [{:notfound_ok, false}])

    {:ok, props} = Riak.Bucket.get "user"
    assert(is_list(props))
    assert(props[:notfound_ok] == false)

    assert(:ok == Riak.Bucket.reset "user")

    {:ok, props} = Riak.Bucket.get "user"
    assert(props[:notfound_ok] == true)
  end

  test "crud operations and siblings" do
    {me, se, mi} = :erlang.now
    key = "#{me}#{se}#{mi}"
    
    u = RObj.create(bucket: "user", key: key, data: "Drew Kerrigan")
      |> Riak.put

    assert(u != nil)

    assert(:ok == Riak.delete "user", u.key)

    u = RObj.create(bucket: "user", data: "Drew Kerrigan")
    assert(u.key == :undefined)
    u = Riak.put u
    assert(u.key != :undefined)

    # Get the object again so we don't create a sibling
    u = Riak.find "user", u.key

    u = u.data("Something Else")
      |> Riak.put

    unewdata = Riak.find "user", u.key

    if is_list(unewdata) and length(unewdata) == 2 do
      Riak.resolve "user", u.key, index_of("Drew Kerrigan", unewdata)

      unewdata = Riak.find "user", u.key

      unewdata
    end

    assert(unewdata.data == "Something Else")

    assert(:ok == Riak.delete "user", u.key)
    assert(:ok == Riak.delete "user", key)

    assert(nil == Riak.find "user", key)
  end

  test "user metadata" do
    {me, se, mi} = :erlang.now
    key = "#{me}#{se}#{mi}"
    mdtest = RObj.create(bucket: "user", key: key, data: "Drew Kerrigan")
      |> RObj.put_metadata({"my_key", "my_value"})
      |> RObj.put_metadata({"my_key2", "my_value2"})
      |> Riak.put
      |> RObj.get_metadata("my_key")

    assert(mdtest == "my_value")

    u = Riak.find "user", key

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
      |> Riak.put

    assert(RObj.get_index(u, {:binary_index, "first_name"}) == ["Drew"])

    {keys, terms, continuation} = Riak.Index.query("user", {:binary_index, "first_name"}, "Drew", [])
    assert(is_list(keys))
    assert(terms == :undefined)
    assert(continuation == :undefined)
    {keys, terms, continuation} = Riak.Index.query("user", {:binary_index, "last_name"}, "Kerrigam", "Kerrigao", [])
    assert(is_list(keys))
    assert(terms == :undefined)
    assert(continuation == :undefined)

    u = RObj.delete_index(u, {:binary_index, "first_name"})
      |> Riak.put

    assert(RObj.get_index(u, {:binary_index, "first_name"}) == nil)
    
    assert(is_list(RObj.get_all_indexes(u)))
    
    indextest = u |> RObj.delete_all_indexes()
      |> RObj.get_all_indexes()

    assert(indextest == [])
  end

  test "links" do
    RObj.create(bucket: "user", key: "drew1", data: "Drew1 Kerrigan")
      |> Riak.put
    RObj.create(bucket: "user", key: "drew2", data: "Drew2 Kerrigan")
      |> Riak.put

    {me, se, mi} = :erlang.now
    key = "#{me}#{se}#{mi}"
    u = RObj.create(bucket: "user", key: key, data: "Drew Kerrigan")
      |> RObj.put_link("my_tag", "user", "drew1")
      |> RObj.put_link("my_tag", "user", "drew2")
      |> Riak.put

    assert(RObj.get_link(u, "my_tag") == [{"user", "drew1"}, {"user", "drew2"}])
    
    assert(RObj.delete_link(u, "my_tag") |> RObj.get_link("my_tag") == nil)

    # Get the object again so we don't create a sibling
    u = Riak.find "user", key

    u   |> RObj.put_link("my_tag", "user", "drew1")
      |> RObj.put_link("my_tag", "user", "drew2")
      |> Riak.put

    assert(RObj.get_link(u, "my_tag") == [{"user", "drew1"}, {"user", "drew2"}])

    assert(is_list(RObj.get_all_links(u)))
    assert(RObj.delete_all_links(u) |> RObj.get_all_links() == [])
  end

  test "ping" do
    assert(Riak.ping == :pong)
  end

  test "siblings" do
    assert(:ok == Riak.Bucket.put "user", [{:allow_mult, true}])

    {me, se, mi} = :erlang.now
    key = "#{me}#{se}#{mi}"

    RObj.create(bucket: "user", key: key, data: "Drew1 Kerrigan")
      |> Riak.put
    RObj.create(bucket: "user", key: key, data: "Drew2 Kerrigan")
      |> Riak.put

    u = Riak.find "user", key

    assert(is_list(u))

    [h|_t] = u

    assert(:ok == Riak.resolve("user", key, 2))
    
    u = Riak.find "user", key

    assert(u.data == h)

    assert(:ok == Riak.Bucket.reset "user")
  end
end