defmodule Riak.CRDT.FlagTest do
  use Riak.Case
  alias Riak.CRDT.Map, as: RiakMap
  alias Riak.CRDT.Flag

  @moduletag :riak2

  test "create a flag" do
    assert {:flag, false, :undefined, :undefined} = Flag.new
  end

  test "create and enable a flag" do
    flag =
      RiakMap.new
        |> RiakMap.put("foo", Flag.new)
        |> RiakMap.update(:flag, "foo", &Flag.enable/1)

      assert flag == {
        :map, [],
        [{{"foo", :flag}, {:flag, false, :enable, :undefined}}],
        [],
        :undefined
      }
  end

  test "create and disable a flag" do
    flag =
      RiakMap.new
        |> RiakMap.put("foo", Flag.new("somecontext"))
        |> RiakMap.update(:flag, "foo", &Flag.disable/1)

    assert flag == {
      :map, [],
      [{{"foo", :flag}, {:flag, false, :disable, "somecontext"}}],
      [],
      :undefined
    }
  end

  test "create and enable a flag, save then get value" do
      RiakMap.new
        |> RiakMap.put("flag_key_true", Flag.new |> Flag.enable)
        |> Riak.update("maps", "flagbucket", "flagmap")

      flag_value = Riak.find("maps", "flagbucket", "flagmap")
        |> RiakMap.get(:flag, "flag_key_true")

      assert flag_value
  end

  test "create and disable a flag, save then get value" do
    flag1 = RiakMap.new
      |> RiakMap.put("flag_key_false", Flag.new |> Flag.enable)
      |> Riak.update("maps", "flagbucket", "flagmap2")

    flag2 = Riak.find("maps", "flagbucket", "flagmap2")
      |> RiakMap.update(:flag, "flag_key_false", &Flag.disable/1)
      |> Riak.update("maps", "flagbucket", "flagmap2")

    flag3 = Riak.find("maps", "flagbucket", "flagmap2")

    # Assert flag is false after we saved the disabled one
    assert RiakMap.get(flag3, :flag, "flag_key_false") == false
  end

end
