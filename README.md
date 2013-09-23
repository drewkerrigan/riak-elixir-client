# Riak Elixir Client

Elixir wrapper for riak-erlang-client

###Setup

Add this project as a depency in your mix.exs

```
defp deps do
	[{ :riak, github: "drewkerrigan/riak-elixir-client" }]
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
	use Riak.Database, host: '127.0.0.1', port: 8087
end
```

###Save a value

```
bucket = "my_bucket"
key = "my_key" # can be nil
data = "drew kerrigan"

Db.put {bucket, key, data}
```

###Find an object

```
case Db.find("my_bucket", "my_key") do
  {:ok, {data, key, metadata, vclock}} -> handle_value(data)
  {:siblings, sibling_list} -> handle_siblings(sibling_list)
  nil -> handle_no_results()
end
```

###Update an object

```
case Db.update {"my_bucket", "my_key", "new data", metadata, vclock} do
  {:ok, {data, key, metadata, vclock}} -> handle_value(data)
  nil
```

###Delete an object

Using key

```
Db.delete "my_bucket", "my_key"
```

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