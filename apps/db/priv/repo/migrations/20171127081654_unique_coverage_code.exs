defmodule Innerpeace.Db.Repo.Migrations.UniqueCoverageCode do
  use Ecto.Migration

  def change do
    create unique_index(:coverages, [:code])
  end
end
