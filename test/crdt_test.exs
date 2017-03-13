defmodule Riak.DatatypeTest do
  use ExUnit.Case
  import Riak.Datatype

  @moduletag :riak2

  test 'type of Register' do
    assert type(Riak.Datatype.Register.new) == :register
    assert type(Riak.Datatype.Register) == :register
    assert type(%Riak.Datatype.Register{}) == :register
  end

  test 'type of Set' do
    assert type(Riak.Datatype.Set.new) == :set
    assert type(Riak.Datatype.Set) == :set
    assert type(%Riak.Datatype.Set{}) == :set
  end

  test 'type of Map' do
    assert type(Riak.Datatype.Map.new) == :map
    assert type(Riak.Datatype.Map) == :map
    assert type(%Riak.Datatype.Map{}) == :map
  end

  test 'type of Flag' do
    assert type(Riak.Datatype.Flag.new) == :flag
    assert type(Riak.Datatype.Flag) == :flag
    assert type(%Riak.Datatype.Flag{}) == :flag
  end

  test 'type of Counter' do
    assert type(Riak.Datatype.Counter.new) == :counter
    assert type(Riak.Datatype.Counter) == :counter
    assert type(%Riak.Datatype.Counter{}) == :counter
  end
end
