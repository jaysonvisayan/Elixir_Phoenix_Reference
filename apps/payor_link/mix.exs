defmodule Innerpeace.PayorLink.Mixfile do
  use Mix.Project

  def project do
    [app: :payor_link,
     version: "2.17.20",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.5",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Innerpeace.PayorLink.Application, []},
     extra_applications: [
       :logger,
       :runtime_tools,
       :db,
       :phoenix_ecto,
       :bamboo,
       :csv,
       :httpoison,
       :pdf_generator,
       :hound,
       :misc_random,
       :sweet_xml,
       :timex,
       :download,
       :recaptcha
       # :exq
       # :ssl
     ]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_html, "~> 2.6"},
      {:phoenix_ecto, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:db, in_umbrella: true},
      {:cowboy, "~> 1.0"},
      {:comeonin, "~> 2.4"},
      {:guardian, "~> 1.1"},
      {:guardian_db, github: "ueberauth/guardian_db"},
      {:bamboo, "~> 0.8"},
      {:csv, "~> 2.0.0"},
      {:httpoison, "~> 0.12"},
      {:pdf_generator, ">=0.3.6"},
      {:hound, "~> 1.0"},
      {:edeliver, "~> 1.4.4"},
      {:distillery, "~> 1.4"},
      {:timex, "~> 3.1"},
      {:cors_plug, "~> 1.2"},
      {:sentry, "~> 6.1.0"},
      {:sobelow, "~> 0.6.9"},
      {:exq, "~> 0.11.0"},
      {:elixlsx, "~> 0.4.0"},
      {:quantum, "~> 2.2"},
      {:mime, "~> 1.2"},
      {:download, "~> 0.0.4"},
      {:plug, "1.5.0"},
      {:recaptcha, "~> 2.3"},
      {:gelf_logger, "~> 0.7.5"}
      # {:cipher, ">= 1.3.4"}
    ]
  end

  defp aliases do
    ["test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
