defmodule Innerpeace.Db.Mixfile do
  use Mix.Project

  def project do
    [app: :db,
     version: "0.1.0",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.5",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {Innerpeace.Db.Application, []},
      applications: [
        :ecto,
        :postgrex,
        :arc,
        :arc_ecto,
        :csv,
        :ex_aws,
        :hackney,
        :poison,
        :timex
      ]
    ]
  end

  defp deps do
    [
      {:ecto, "~> 2.1"},
      {:postgrex, ">= 0.0.0"},
      {:ex_machina, ">= 1.0.0", only: :test},
      {:comeonin, "~> 2.4"},
      {:csv, "~> 2.0.0"},
      {:arc, "~> 0.8.0"},
      {:arc_ecto, "~> 0.7.0"},
      {:ex_aws, "~> 1.1"},
      {:hackney, "~> 1.6"},
      {:poison, "~> 3.1"},
      {:httpoison, "~> 0.12"},
      {:sweet_xml, "~> 0.6"},
      {:timex, "~> 3.1"},
      {:plug, "~> 1.3.3 or ~> 1.4"},
      {:oauth2, "~> 0.9"},
      {:elixlsx, "~> 0.4.0"},
      {:cipher, ">= 1.3.4"},
      {:exq, "~> 0.11.0"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"]
    ]
  end
end
