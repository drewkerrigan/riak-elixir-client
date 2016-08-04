defmodule Riak.Datatype.FlagTest do
  use Riak.Case
  alias Riak.Datatype.Map, as: RiakMap
  alias Riak.Datatype.Flag

  @moduletag :riak2

  test "create a flag" do
    assert false == Flag.new |> Flag.value
  end

  test "create and enable a flag" do
    flag_map = RiakMap.new |> RiakMap.put("foo", Flag.new(true))
    assert flag_map.updates == %{foo: %Flag{op: :enable}}
  end

  test "create and disable a flag" do
    flag_map = RiakMap.new |> RiakMap.put("foo", Flag.new(false))
    assert flag_map.updates == %{foo: %Flag{op: :disable}}
  end

  test "create and enable a flag, save then get value" do
    RiakMap.new
    |> RiakMap.put("flag_key_true", Flag.new |> Flag.enable)
    |> Riak.Datatype.put({"maps", "flagbucket"}, "flagmap")

    flag_value = Riak.Datatype.find({"maps", "flagbucket"}, "flagmap")
    |> RiakMap.get_value("flag_key_true")

    assert flag_value == true
  end

  test "create and disable a flag, save then get value" do
    RiakMap.new
    |> RiakMap.put("flag_key_false", Flag.new(true))
    |> Riak.Datatype.put({"maps", "flagbucket"}, "flagmap2")

    Riak.Datatype.find({"maps", "flagbucket"}, "flagmap2")
    |> RiakMap.update!("flag_key_false", &Flag.disable/1)
    |> Riak.Datatype.update({"maps", "flagbucket"}, "flagmap2")

    flag3 = Riak.Datatype.find({"maps", "flagbucket"}, "flagmap2")

    # Assert flag is false after we saved the disabled one
    assert RiakMap.get_value(flag3, "flag_key_false") == false
  end

end
