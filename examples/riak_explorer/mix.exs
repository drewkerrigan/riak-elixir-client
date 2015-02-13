defmodule RiakExplorer.Mixfile do
  use Mix.Project

  def project do
    [ app: :riak_explorer,
      version: "0.0.1",
      elixir: "~> 1.0",
      deps: deps,
      escript: escript ]
  end

  def escript do
    [ main_module: RiakExplorer,
      app: :riak ]
  end

  def application do
    [ applications: [ :riak ]]
  end

  defp deps do
    #[ {:riak, "~> 1.0"} ]
    [ {:riak, github: "drewkerrigan/riak-elixir-client"} ]
  end
end