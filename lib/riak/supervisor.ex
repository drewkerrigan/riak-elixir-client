defmodule Riak.Supervisor do
  @moduledoc """
  Riak Client's base supervisor.
  """
  use Supervisor.Behaviour

  @doc """
  Start the supervisor.
  """
  def start_link() do
    :supervisor.start_link(__MODULE__, nil)
  end

  @doc false
  def init(_) do
    children = [ worker(Riak.Client, []) ]
    supervise children, strategy: :one_for_one
  end
end