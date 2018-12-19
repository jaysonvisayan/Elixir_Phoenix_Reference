defmodule MemberLink.Mixfile do
  use Mix.Project

  def project do
    [
      app: :member_link,
      version: "2.2.3",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
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
      mod: {MemberLink.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :httpoison,
        :db,
        :phoenix_ecto,
        :bamboo,
        :pdf_generator,
        :timex,
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
      {:edeliver, "~> 1.4.4"},
      {:guardian, "~> 1.1"},
      {:pdf_generator, ">=0.3.6"},
      #{:guardian_db, github: "ueberauth/guardian_db"},
      {:distillery, "~> 1.4"},
      {:httpoison, "~> 0.12"},
      {:comeonin, "~> 2.4"},
      {:bamboo, "~> 0.8"},
      {:timex, "~> 3.1"},
      {:sentry, "~> 6.1.0"}
    ]
  end
end
