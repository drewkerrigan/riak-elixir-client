defmodule Riak.Mixfile do
  use Mix.Project

  def project do
    [ app: :'riak-elixir-client',
      version: "0.0.1",
      elixir: "~> 0.11.3-dev",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [ registered: [:riak],
      mod: { Riak, [] }]
  end

  defp deps do
    [{ :riakc, github: "basho/riak-erlang-client", tag: "1.4.1" }]
  end
end
