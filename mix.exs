defmodule Riak.Mixfile do
  use Mix.Project

  def project do
    [ app: :riak,
      version: "1.1.6",
      build_per_environment: false,
      name: "Riak Elixir Client",
      source_url: "https://github.com/drewkerrigan/riak-elixir-client",
      deps: deps(),
      description: description(),
      package: package() ]
  end

  # Configuration for the OTP application
  def application do
    [ applications: [ :pooler ],
      included_applications: [ :riakc ] ]
  end

  defp deps do
    [ {:ex_doc, ">= 0.0.0", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev},
      {:pooler, "~> 1.5.3"},
      {:riakc, "~> 2.5.3"} ]
  end

  defp description do
    """
    A Riak client written in Elixir.
    """
  end

  defp package do
    [ files: ~w(config doc examples lib test LICENSE mix.exs mix.lock README.md THANKS),
      maintainers: [ "Drew Kerrigan", "Eduardo Gurgel", "Randy Secrist" ],
      licenses: [ "Apache 2.0" ],
      links: %{"GitHub" => "https://github.com/drewkerrigan/riak-elixir-client",
               "Documentation" => "http://hexdocs.pm/riak"} ]
  end
end
