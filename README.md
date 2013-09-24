# Riak Elixir Client

Elixir wrapper for riak-erlang-client

###Setup

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

###Create a reference to your Riak instance

```
defmodule Db do
  use Riak.Client, host: '127.0.0.1', port: 8087
end
```

###Save a value

```
u = RObj.create(bucket: "user", key: "my_key", data: "Drew Kerrigan")
  |> Db.put
```

###Find an object

```
u = Db.find "user", "my_key"
```

###Update an object

```
u = u.data("Something Else")
  |> Db.put
```

###Delete an object

Using key

```
Db.delete "user", key
```

Using object

```
Db.delete u
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