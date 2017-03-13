defmodule Riak do
  @moduledoc """
  # Riak Elixir Client
  [![Build Status](https://travis-ci.org/drewkerrigan/riak-elixir-client.svg?branch=master)](https://travis-ci.org/drewkerrigan/riak-elixir-client)

  A Riak client written in Elixir.  Now includes connection pooling with [pooler](http://github.com/seth/pooler) and a variety of other improvements from [riex](https://github.com/edgurgel/riex).

  ## Setup

  ### Prerequisites

  * Riak 2.0+
  * Elixir 1.0+

  #### In an Elixir application

  Add the following to mix.exs

  ```elixir
  ...
  def application do
    [ applications: [ :riak ]]
  end
  ...
  defp deps do
    [ {:riak, "~> 1.0"} ]
  end
  ...
  ```

  ## Usage

  ### Establishing a Riak connection

  ```elixir
  {:ok, pid} = Riak.Connection.start_link('127.0.0.1', 8087) # Default values
  ```

  ### Connection Pooling

  Most functions in this module can be called by passing the pid of the established connection or using a pool of connections (provided by pooler).  Define pools by using the group `riak`.  Following is an example `config/config.exs`:

  ```elixir
  [pooler: [pools: [
    [ name: :riaklocal1,
      group: :riak,
      max_count: 10,
      init_count: 5,
      start_mfa: {Riak.Connection, :start_link, []}
    ],
     [ name: :riaklocal2,
      group: :riak,
      max_count: 15,
      init_count: 2,
      start_mfa: {Riak.Connection, :start_link, ['127.0.0.1', 9090]}
    ] ]
  ]]

  ```

  For an example using this functionality with a local Riak instance, check [`config/config.exs`](https://github.com/drewkerrigan/riak-elixir-client/blob/master/config/config.exs).  More information about Elixir configuration can be found on [http://elixir-lang.org(http://elixir-lang.org)]: [Application environment and configuration](http://elixir-lang.org/getting_started/mix_otp/10.html#toc_6).

  Once a pool configuration is properly defined in a project, calls to Riak can omit the pid.  For example:

  This call uses a pid from the pool of connections provided by pooler:

  ```elixir
  Riak.delete("user", key)
  ```

  This call requires a pid obtained by first calling `Riak.Connection.start_link`:

  ```elixir
  Riak.delete(pid, "user", key)
  ```

  ### Save a value

  ```elixir
  o = Riak.Object.create(bucket: "user", key: "my_key", data: "Han Solo")
  Riak.put(pid, o)
  ```

  ### Find an object

  ```elixir
  o = Riak.find(pid, "user", "my_key")
  ```

  ### Update an object

  ```elixir
  o = %{o | data: "Something Else"}
  Riak.put(pid, o)
  ```

  ### Delete an object

  Using key

  ```elixir
  Riak.delete(pid, "user", key)
  ```

  Using object

  ```elixir
  Riak.delete(pid, o)
  ```

  ### Datatypes

  Riak Datatypes (a.k.a. CRDTs) are avaiable in [Riak versions 2.0](http://basho.com/introducing-riak-2-0/) and greater.  The types included are: maps, sets, counters, registers and flags.

  #### Setup

  Datatypes require the use of bucket-types.  Maps, sets, and counters can be used as top-level bucket-type datatypes; Registers and flags may only be used within maps.

  The following examples assume the presence of 3 datatype enabled bucket-types.  You can create these bucket-types by running the following commands on a single Riak node in your cluster:

  Bucket-Type: `counters`

  ```
  riak-admin bucket-type create counters '{"props":{"datatype":"counter"}}'
  riak-admin bucket-type activate counters
  ```

  Bucket-Type: `sets`

  ```
  riak-admin bucket-type create sets '{"props":{"datatype":"set"}}'
  riak-admin bucket-type activate sets
  ```

  Bucket-Type: `maps`

  ```
  riak-admin bucket-type create maps '{"props":{"datatype":"map"}}'
  riak-admin bucket-type activate maps
  ```

  #### Counters

  Create a counter (`alias Riak.Datatype.Counter`):

  ```elixir
  Counter.new
    |> Counter.increment
    |> Counter.increment(2)
    |> Riak.update("counters", "my_counter_bucket", "my_key")
  ```

  Fetch a counter:

  ```elixir
  counter = Riak.find("counters", "my_counter_bucket", "my_key")
    |> Counter.value
  ```

  `counter` will be 3.

  ***NOTE***: "Counter drift" is a possibility that needs to be accounted for with any distributed system such as Riak.  The problem can manifest itself during failure states in either your applicaiton or Riak itself.  If an increment operation fails from the client's point of view, there is not sufficient information available to know whether or not that call made it to zero or all of the replicas for that counter object.  As such, if the client attempts to retry the increment after recieving something like a error code 500 from Riak, that counter object is at risk of drifting positive.  Similarly if the client decides not to retry, that counter object is at risk of drifting negative.

  For these reasons, counters are only suggested for use-cases that can handle some (albeit small) amount of counter drift.  Good examples of appropriate use-cases are: Facebook likes, Twitter retweet counts, Youtube view counts, etc.  Some examples of poor use-cases for Riak counters are: bank account balances, anything related to money.  It is possible to implement these types of solutions using Riak, but more client side logic is necessary.  For an example of a client-side ledger with tunable retry options, check [github.com/drewkerrigan/riak-ruby-ledger](https://github.com/drewkerrigan/riak-ruby-ledger).  Another approach could be the client-side implementation of a HAT (Highly Available Transaction) algorithm.

  #### Sets

  Create a set (`alias Riak.Datatype.Set`):

  ```elixir
  Set.new
    |> Set.put("foo")
    |> Set.put("bar")
    |> Riak.update("sets", "my_set_bucket", "my_key")
  ```

  And fetch the set:

  ```elixir
  set = Riak.find("sets", "my_set_bucket", "my_key")
    |> Set.value
  ```

  Where `set` is an `orddict`.

  #### Maps

  Maps handle binary keys with any other datatype (map, set, flag, register and counter).

  Create a map (`alias Riak.Datatype.Map`):

  ```elixir
  register = Register.new("some string")
  flag = Flag.new |> Flag.enable
  Map.new
    |> Map.put("k1", register)
    |> Map.put("k2", flag)
    |> Riak.update("maps", "my_map_bucket", "map_key")
  ```

  And fetch the map:

  ```elixir
  map = Riak.find("maps", "my_map_bucket", key) |> Map.value
  ```

  Where `map` is an `orddict`.

  ## Examples

  Check the `examples/` directory for a few example elixir applications using the riak client.

  For more functionality, check `test/` directory.

  ## Tests

  ```
  MIX_ENV=test mix do deps.get, test
  ```

  ## License

      Copyright 2015 Drew Kerrigan.
      Copyright 2014 Eduardo Gurgel.

      Licensed under the Apache License, Version 2.0 (the "License");
      you may not use this file except in compliance with the License.
      You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

      Unless required by applicable law or agreed to in writing, software
      distributed under the License is distributed on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
      See the License for the specific language governing permissions and
      limitations under the License.

  """
  import Riak.Pool
  require Record

  @doc """
  Ping the server.
  """
  defpool ping(pid) when is_pid(pid), do: :riakc_pb_socket.ping(pid)

  @doc """
  Put the metadata/value in the object under bucket-type/bucket/key.
  """
  defpool put(pid, obj) when is_pid(pid) do
    case :riakc_pb_socket.put(pid, Riak.Object.to_record(obj)) do
      {:ok, new_key} when is_binary(new_key) -> %{obj | key: new_key}
      {:ok, new_object} -> %{obj | key: :riakc_obj.key(new_object)}
      :ok -> obj
      _ -> nil
    end
  end

  @doc """
  Get bucket-type/bucket/key from the server.
  """
  defpool find(pid, bucket, key) when is_pid(pid) and (is_binary(bucket) or is_tuple(bucket)) do
    case :riakc_pb_socket.get(pid, bucket, key) do
      {:ok, object} ->
        if :riakc_obj.value_count(object) > 1 do
          build_sibling_list(:riakc_obj.get_contents(object),[])
        else
          Riak.Object.from_robj(object)
        end
      _ -> nil
    end
  end
  defpool find(pid, bucket_type, bucket, key) when is_pid(pid) do
    find(pid, {bucket_type, bucket}, key)
  end

  # [["X-Riak-Deleted" | true]]
  defp sibling_deleted?(md) do
    presented = md
                |> :dict.fetch_keys
                |> Enum.find(& &1 == "X-Riak-Deleted")
    presented && :dict.fetch("X-Riak-Deleted", md)
  end
  defp build_sibling_list([], [final_list]), do: %Riak.Object{data: final_list}
  defp build_sibling_list([], final_list), do: final_list
  defp build_sibling_list([{md, val}|t], final_list) do
    build_sibling_list(t, (if sibling_deleted?(md), do: final_list, else: [val|final_list]))
  end

  @doc """
  Picks the sibling to "win" over the other siblings via a list index.
  """
  defpool resolve(pid, bucket, key, index) when is_pid(pid) do
    case :riakc_pb_socket.get(pid, bucket, key) do
      {:ok, object} ->
        new_object = :riakc_obj.select_sibling(index, object)
        :riakc_pb_socket.put(pid, new_object)
      _ -> nil
    end
  end

  @doc """
  Delete the key/value.
  """
  defpool delete(pid, obj) when is_pid(pid), do: delete(pid, obj.bucket, obj.key)
  defpool delete(pid, {_bucket_type, _bucket}=b, key) when is_pid(pid), do: :riakc_pb_socket.delete(pid, b, key)
  defpool delete(pid, bucket, key) when is_pid(pid) and is_binary(bucket), do: :riakc_pb_socket.delete(pid, bucket, key)
  defpool delete(pid, bucket_type, bucket, key) when is_pid(pid), do: delete(pid, {bucket_type, bucket}, key)
end
