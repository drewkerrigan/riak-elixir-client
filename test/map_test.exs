defmodule Riak.CRDT.MapTest do
  require IEx
  use Riak.Case
  alias Riak.CRDT.Map
  alias Riak.CRDT.Register
  alias Riak.CRDT.Flag
  alias Riak.CRDT.Counter
  alias Riak.CRDT.Set

  @moduletag :riak2

  test "create, update and find a map with other CRDTs" do
    key = Riak.Helper.random_key

    reg_data = "Register data"
    reg = Register.new(reg_data)
    reg_key = "register_key"

    flag = Flag.new |> Flag.enable
    flag_key = "flag_key"

    counter = Counter.new |> Counter.increment
    counter_key = "counter_key"

    set = Set.new |> Set.put("foo")
    set_key = "set_key"

    Map.new
      |> Map.put(reg_key, reg)
      |> Map.put(flag_key, flag)
      |> Map.update(:counter, counter_key, fn _ -> counter end)
      |> Map.put(set_key, set)
      |> Riak.update("maps", "bucketmap", key)

    map = Riak.find("maps", "bucketmap", key)
      |> Map.value

    map_keys = :orddict.fetch_keys(map)
    assert {"counter_key", :counter} in map_keys
    assert {"flag_key", :flag} in map_keys
    assert {"register_key", :register} in map_keys
    assert {"set_key", :set} in map_keys

    assert :orddict.size(map) == 4

    data = :orddict.to_list(map)
    assert {{reg_key, :register}, reg_data} in data
    assert {{flag_key, :flag}, true} in data
    assert {{counter_key, :counter}, 1} in data
    assert {{set_key, :set}, ["foo"]} in data
  end

  test "create, update and find nested maps" do
    key = Riak.Helper.random_key

    flag = Flag.new |> Flag.enable
    flag_key = "flag_key"
    nested = Map.new |> Map.put(flag_key, flag)
    nested_key = "nested_key"

    Map.new
      |> Map.put(nested_key, nested)
      |> Riak.update("maps", "bucketmap", key)

    map = Riak.find("maps", "bucketmap", key)

    value_map = map |> Map.value

    assert :orddict.size(value_map) == 1

    assert :orddict.fetch({"nested_key", :map}, value_map) == [{{"flag_key", :flag}, true}]
  end

  test "create, update, delete map" do
    #   m = Riak.find(riak, "maps", "users", "1d1cf86e-e7c8-11e4-b576-542696dfbfa9") |> Riak.CRDT.Map.value
    #   :ok = Riak.delete(riak, "users", "1d1cf86e-e7c8-11e4-b576-542696dfbfa9") # Doesn't delete it
    #   Riak.delete(riak, "maps", "users", "1d1cf86e-e7c8-11e4-b576-542696dfbfa9") # No such function - errors out
    key = Riak.Helper.random_key

    Map.new
      |> Map.put("register_key", Register.new("Some Data"))
      |> Riak.update("maps", "users", key)

    reg_data = Riak.find("maps", "users", key)
      |> Map.get(:register, "register_key")

    assert "Some Data" == reg_data

    Riak.delete("maps", "users", key)
    assert Riak.find("maps", "users", key) == nil

  end
end
