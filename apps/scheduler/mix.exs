defmodule Scheduler.Mixfile do
  use Mix.Project

  @version "0.1.15"

  def project do
    [
      app: :scheduler,
      version: @version,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Scheduler.Application, []},
      extra_applications: [
        :logger,
        :timex
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:db, in_umbrella: true},
      {:timex, "~> 3.1"},
      {:edeliver, "~> 1.4.4"},
      {:distillery, "~> 1.4"},
      {:quantum, "~> 2.2"}
    ]
  end
end
