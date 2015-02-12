defmodule Riak.Connection do
  def start_link(host \\ '127.0.0.1', port \\ 8087) do
    :riakc_pb_socket.start_link(host, port)
  end

  def start(host \\ '127.0.0.1', port \\ 8087) do
    :riakc_pb_socket.start(host, port)
  end
end
