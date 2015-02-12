defmodule Riak.Mixfile do
  use Mix.Project

  def project do
    [ app: :riak,
      version: "0.1.0",
      elixir: "~> 1.0",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [included_applications: [:riakc]]
  end

  defp deps do
    [{:meck, github: "eproxus/meck", tag: "0.8.2", override: true},
     {:riak_pb, github: "basho/riak_pb", override: true, tag: "2.0.0.16", compile: "./rebar get-deps compile deps_dir=../"},
     {:riakc, github: "basho/riak-erlang-client", tag: "2.0.1"}]
  end
end
