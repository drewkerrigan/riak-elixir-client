defmodule Riak.Mixfile do
  use Mix.Project

  def project do
    [ app: :riak,
      version: "1.0.0",
      elixir: "~> 1.0",
      deps: deps,
      build_per_environment: false,
      name: "Riak Elixir Client",
      source_url: "https://github.com/drewkerrigan/riak-elixir-client",
      description: description,
      package: package ]
  end

  # Configuration for the OTP application
  def application do
    [ applications: [ :pooler ],
      included_applications: [ :riakc ] ]
  end

  defp deps do
    [ {:earmark, only: :dev},
      {:ex_doc, only: :dev},
      {:linguist, "~> 0.1"},
      {:pooler, "~> 1.5"},
      {:riakc, git: "git://github.com/drewkerrigan/riak-erlang-client.git", branch: "riak_ts-develop-1.2"} ]
  end

  defp description do
    """
    A Riak client written in Elixir.
    """
  end

  defp package do
    [ files: ~w(config doc examples lib test LICENSE mix.exs mix.lock README.md THANKS),
      maintainers: [ "Drew Kerrigan", "Eduardo Gurgel" ],
      licenses: [ "Apache 2.0" ],
      links: %{"GitHub" => "https://github.com/drewkerrigan/riak-elixir-client",
               "Documentation" => "http://hexdocs.pm/riak"} ]
  end
end
