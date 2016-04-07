defmodule Riak.Connection do
  @doc """
  Create a linked process to talk with the riak server on host:port.
  """
  def start_link(host \\ '127.0.0.1', port \\ 8087, args \\ []) do
    :riakc_pb_socket.start_link(host, port, args)
  end

  @doc """
  Create a process to talk with the riak server on host:port.
  """
  def start(host \\ '127.0.0.1', port \\ 8087, args \\ []) do
    :riakc_pb_socket.start(host, port, args)
  end
end
