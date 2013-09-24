defmodule Riak.Mixfile do
  use Mix.Project

  def project do
    [ app: :'riak-elixir-client',
      version: "0.0.1",
      elixir: "~> 0.10.2",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [ registered: [:riak],
      mod: { Riak, [] }]
  end

  defp deps do
    [{ :riakc, github: "basho/riak-erlang-client" }]
  end
end
