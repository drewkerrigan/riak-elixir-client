defmodule Riak.CRDTTest do
  use ExUnit.Case
  import Riak.CRDT

  test 'type of Register' do
    assert type(Riak.CRDT.Register.new) == :register
  end

  test 'type of Set' do
    assert type(Riak.CRDT.Set.new) == :set
  end

  test 'type of Map' do
    assert type(Riak.CRDT.Map.new) == :map
  end

  test 'type of Flag' do
    assert type(Riak.CRDT.Flag.new) == :flag
  end

  test 'type of Counter' do
    assert type(Riak.CRDT.Counter.new) == :counter
  end
end
