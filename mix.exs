defmodule Riak.Mixfile do
  use Mix.Project

  def project do
    [ app: :'riak-elixir-client',
      version: "0.0.2",
      elixir: "~> 1.0.0",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:riak]]
  end

  defp deps do
    [{ :riakc, github: "basho/riak-erlang-client"}]
  end
end
