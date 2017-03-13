defmodule Riak.Datatype.MapTest do
  require IEx
  use Riak.Case
  alias Riak.Datatype.Map
  alias Riak.Datatype.Register
  alias Riak.Datatype.Flag

  @moduletag :riak2

  test "create, update and find a map with other CRDTs" do
    key = Riak.Helper.random_key
    bucket = {"maps", "bucketmap"}

    Map.new(%{register_key: "Register Data",
              flag_key: true,
              counter_key: 1,
              set_key: ["foo"]})
              |> Riak.Datatype.put(bucket, key)

    map = Riak.Datatype.find(bucket, key)
    assert Map.has_key?(map, :counter_key)
    assert Map.has_key?(map, :flag_key)
    assert Map.has_key?(map, :register_key)
    assert Map.has_key?(map, :set_key)
    assert Enum.count(map) == 4

    data = Map.value(map)
    assert data.register_key == "Register Data"
    assert data.flag_key == true
    assert data.counter_key == 1
    assert data.set_key == ["foo"]
  end

  test "create, update and find nested maps" do
    key = Riak.Helper.random_key
    bucket = {"maps", "bucketmap"}

    Riak.Datatype.new(%{nested_key: %{flag_key: true}})
    |> Riak.Datatype.put(bucket, key)

    map = Riak.Datatype.find(bucket, key)
    flag = Map.get(map, :nested_key) |> Map.get(:flag_key)
    assert Enum.count(map) == 1
    assert Flag.value(flag) == true
    assert Map.has_key?(map, :nested_key) == true

    Riak.Datatype.find(bucket, key)
    |> Map.delete(:nested_key)
    |> Riak.Datatype.update(bucket, key)

    map = Riak.Datatype.find(bucket, key)
    assert Map.has_key?(map, :nested_key) == false
  end

  test "create, update, delete map" do
    key = Riak.Helper.random_key
    bucket = {"maps", "users"}

    Map.new(%{register_key: Register.new("Some Data")})
    |> Riak.Datatype.put(bucket, key)

    reg = Riak.Datatype.find(bucket, key)
    |> Map.get(:register_key)

    assert "Some Data" == Register.value(reg)

    Riak.Datatype.delete(bucket, key)
    assert Riak.Datatype.find(bucket, key) == nil
  end

  test "map key exists" do
    key = Riak.Helper.random_key
    bucket = {"maps", "users"}

    Map.new
    |> Map.put("register_key", "Some Data")
    |> Riak.Datatype.update(bucket, key)

    map = Riak.Datatype.find(bucket, key)
    assert Map.has_key?(map, "nothere") == false
    assert Map.has_key?(map, "register_key") == true
    assert Map.keys(map) == [:register_key]
  end
end
