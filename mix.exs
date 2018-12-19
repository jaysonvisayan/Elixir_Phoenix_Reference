defmodule Innerpeace.Mixfile do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  defp deps do
    [
      {:edeliver, "~> 1.4.4"},
      {:distillery, "~> 1.4"},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dogma, "~> 0.1", only: :dev},
      {:number, "~> 0.5.6"},
      {:sobelow, "~> 0.6.9"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run apps/db/priv/repo/seeds-new.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.reset-no-seed": ["ecto.drop", "ecto.setup-no-seed"],
      "ecto.setup-no-seed": ["ecto.create", "ecto.migrate"],
      "ecto.seed": ["run apps/db/priv/repo/seeds-new.exs"]
    ]
  end
end
