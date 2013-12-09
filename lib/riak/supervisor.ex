defmodule Riak.Supervisor do
  use Supervisor.Behaviour

  def start_link() do
    :supervisor.start_link(__MODULE__, nil)
  end

  def init(_) do
    children = [ worker(Riak.Client, []) ]
    supervise children, strategy: :one_for_one
  end
end