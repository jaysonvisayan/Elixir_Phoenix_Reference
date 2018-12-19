defmodule RegistrationLink.Mixfile do
  use Mix.Project

  def project do
    [
      app: :registration_link,
      version: "0.4.9",
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
      mod: {RegistrationLink.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :db,
        :bamboo,
        :phoenix_ecto,
        :httpoison,
        :sweet_xml
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
      {:phoenix_ecto, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:db, in_umbrella: true},
      {:cowboy, "~> 1.0"},
      {:guardian, "~> 1.1"},
      {:guardian_db, github: "ueberauth/guardian_db"},
      {:comeonin, "~> 2.4"},
      {:distillery, "~> 1.4"},
      {:edeliver, "~> 1.4.4"},
      {:bamboo, "~> 0.8"},
      {:httpoison, "~> 0.12"},
      {:sentry, "~> 6.1.0"},
      {:zbar, "~> 0.1.0"}
    ]
  end
end
