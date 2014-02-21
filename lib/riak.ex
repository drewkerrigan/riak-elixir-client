defmodule Riak do
  @moduledoc """
  A Client for Riak.

  ## Setup
  The `start` function starts the OTP application, and `configure`
  sends a message to the OTP server running locally which starts
  the protobuf link with your Riak cluster.

      iex> Riak.start
      iex> Riak.configure(host: '127.0.0.1', port: 8087)

  The client supports secondary indexes. Remember to use a storage
  backend that support secondary indexes (such as *leveldb*), in
  your Riak configuration.

  ## Basic CRUD operations
  Data is inserted into the database using the `put` function. The
  inserted data needs to be an `RObj` created like this:

      iex> u = RObj.create(bucket: "user", key: "my_key", data: "Drew Kerrigan")
      iex> Riak.put u

  To get a data entry out of the database, use the `find` function.

      iex> u = Riak.find "user", "my_key"

  Updating data is done with by fetching a data entry, updating its
  data and putting it back into the database using `find` and `put`.

      iex> u = Riak.find "user", "my_key"
      iex> u = u.data("Updated Data")
      iex> Riak.put u

  Deleting data from the database is done using the `delete` function.

      iex> Riak.delete "user", "my_key"

  The client support secondary indexes, links and siblings. This is
  work in progress, and any help is greatly appreciated. Fork the code
  on [github](https://github.com/drewkerrigan/riak-elixir-client).
  """

  use Application.Behaviour

  defrecord State, socket_pid: nil

  use Riak.Client

  def start() do
    Riak.Supervisor.start_link()
  end

  def start(_type, _state) do
    Riak.Supervisor.start_link()
  end
end
