defmodule RiakExplorer.Mixfile do
  use Mix.Project

  def project do
    [app: :riak_explorer,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps,
     escript_main_module: ExMessengerClient]
  end

  def application do
    [ applications: [ :riak ]]
  end

  defp deps do
    #[ {:riak, "~> 1.0"} ]
    [ {:riak, github: "drewkerrigan/riak-elixir-client"} ]
  end
end