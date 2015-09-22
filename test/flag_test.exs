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
      |> RiakMap.put("foo", Flag.new)
      |> RiakMap.update(:flag, "foo", &Flag.disable/1)

    assert flag == {
      :map, [],
      [{{"foo", :flag}, {:flag, false, :disable, :undefined}}],
      [],
      :undefined
    }
  end
end
