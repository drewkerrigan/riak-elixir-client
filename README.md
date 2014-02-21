# Riak Elixir Client

Elixir wrapper for riak-erlang-client

###Setup

#### Prerequisites

You should have at least one Riak node running. If you plan to use secondary indexes, you'll need to have the leveldb backend enabled:

`app.config` in version 1.4.x-

```
[
    ...
    {riak_kv, [
        {storage_backend, riak_kv_eleveldb_backend},
        ...
            ]},
    ...
].
```

or `riak.conf` in version 2.x.x+

```
...
storage_backend = leveldb
...
```

#### In your Elixir application

Add this project as a depency in your mix.exs

```
defp deps do
	[{ :'riak-elixir-client', github: "drewkerrigan/riak-elixir-client" }]
end
```

Install dependencies

```
mix deps.get
```

Compile

```
mix
```

###Configure Riak

```
Riak.start
Riak.configure(host: '127.0.0.1', port: 10017)
```

###Save a value

```
u = RObj.create(bucket: "user", key: "my_key", data: "Drew Kerrigan")
  |> Riak.put
```

###Find an object

```
u = Riak.find "user", "my_key"
```

###Update an object

```
u = u.data("Something Else")
  |> Riak.put
```

###Delete an object

Using key

```
Riak.delete "user", key
```

Using object

```
Riak.delete u
```

####For a more functionality, check `test/riak_test.exs`

###Run tests

```
mix test
```

### License

Copyright 2012-2013 Drew Kerrigan.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
