defmodule Worker.Mixfile do
  use Mix.Project

  def project do
    [
      app: :worker,
      version: "0.6.14",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Worker.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :db,
        :bamboo,
        :exq,
        :exq_ui
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:exq, "~> 0.11.0"},
      {:exq_ui, "~> 0.9.0"},
      {:edeliver, "~> 1.4.4"},
      {:distillery, "~> 1.4"},
      {:db, in_umbrella: true},
      {:bamboo, "~> 0.8"},
      {:comeonin, "~> 2.4"}
    ]
  end
end
