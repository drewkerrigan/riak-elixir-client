# Riak Elixir Client [![Build Status](https://travis-ci.org/drewkerrigan/riak-elixir-client.svg?branch=master)](https://travis-ci.org/drewkerrigan/riak-elixir-client)

A Riak client written in Elixir. Now includes a variety of improvements and refactors from [riex](https://github.com/edgurgel/riex).

Included applications:

* Pool of connections using [pooler](http://github.com/seth/pooler)
* Riak Erlang Client [riak-erlang-client](http://github.com/basho/riak-erlang-client)

##Setup

### Prerequisites

* Riak 2.0+
* Elixir 1.0+
* Erlang 17.0+

#### In your Elixir application

Add the following to your mix.exs

```elixir
...
defp deps do
  [ {:riak, "~> 1.0"} ]
end
...
def application do
  [ applications: [ :riak ]]
end
```

# Usage

One can pass the pid of the established connection or just use the pool (provided by pooler). You just need to define your pools using the group "riak. For example having this on your `config/config.exs`:

```elixir
[pooler: [pools: [
  [ name: :riaklocal1,
    group: :riak,
    max_count: 10,
    init_count: 5,
    start_mfa: {Riex.Connection, :start_link, []}
  ],
   [ name: :riaklocal2,
    group: :riak,
    max_count: 15,
    init_count: 2,
    start_mfa: {Riex.Connection, :start_link, ['127.0.0.1', 9090]}
  ] ]
]]

```

Check Riex [`config/config.exs`](https://github.com/edgurgel/riex/blob/master/config/config.exs) for an example on the pool configuration for a local Riak. More info about configuration on Elixir website: [Application environment and configuration](http://elixir-lang.org/getting_started/mix_otp/10.html#toc_6).

After this pool configuration, any call to Riex can omit the pid if you want to use the pool.

For example:

```elixir
Riex.delete(pid, "user", key)

Riex.delete("user", key)
```

The first call will use the pid you started using `Riex.Connection` and the second call will get a connection from the pool of connections provided by pooler.

##Establishing a Riex connection

```elixir
{:ok, pid} = Riex.Connection.start_link('127.0.0.1', 8087) # Default values
```

##Save a value

```elixir
o = Riex.Object.create(bucket: "user", key: "my_key", data: "Drew Kerrigan")
Riex.put(pid, o)
```

##Find an object

```elixir
o = Riex.find(pid, "user", "my_key")
```

##Update an object

```elixir
o = %{o | data: "Something Else"}
Riex.put(pid, o)
```

##Delete an object

Using key

```elixir
Riex.delete(pid, "user", key)
```

Using object

```elixir
Riex.delete(pid, o)
```

## CRDTs

Riak Datatypes are avaiable since [Riak 2.0](http://basho.com/introducing-riak-2-0/). The types included are: maps, sets, counters, registers and flags.

### Counters

Considering that you created the "counter_bucket" bucket type using something like:

```
riak-admin bucket-type create counter_bucket '{"props":{"datatype":"counter"}}'
riak-admin bucket-type activate counter_bucket
```

One can create a counter (Riex.CRDT.Counter):

```elixir
Counter.new
  |> Counter.increment
  |> Counter.increment(2)
  |> Riex.update("counter_bucket", "bucketcounter", "my_key")
```

And fetch the counter:

```elixir
counter = Riex.find("counter_bucket", "bucketcounter", my_key)
  |> Counter.value
```

`counter` will be 3.

### Sets

Considering that you created the "set_bucket" bucket type using something like:

```
riak-admin bucket-type create set_bucket '{"props":{"datatype":"set"}}'
riak-admin bucket-type activate set_bucket
```

Now one can create a set (Riex.CRDT.Set):

```elixir
Set.new
  |> Set.put("foo")
  |> Set.put("bar")
  |> Riex.update("set_bucket", "bucketset", "my_key")
```

And fetch the set:

```elixir
set = Riex.find("set_bucket", "bucketset", "my_key")
  |> Set.value
```

Where `set` is an orddict.

### Maps

Maps handle binary keys with any other datatype (map, set, flag, register and counter).

Considering that you created the "map_bucket" bucket type using something like:

```
riak-admin bucket-type create set_bucket '{"props":{"datatype":"map"}}'
riak-admin bucket-type activate map_bucket
```

Now one can create a map (Riex.CRDT.Map):

```elixir
register = Register.new("data")
flag = Flag.new |> Flag.enable
Map.new
  |> Map.put("k1", register)
  |> Map.put("k2", flag)
  |> Riex.update("map_bucket", "bucketmap", "map_key")
```

And fetch the map:

```elixir
map = Riex.find("map_bucket", "bucketmap", key) |> Map.value
```

Where map is an `orddict`.

# Examples

Check the `examples/` directory for a few example elixir applications using the riak client. 

For a more functionality, check `test/` directory.

##Tests

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
