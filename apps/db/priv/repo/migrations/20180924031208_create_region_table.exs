defmodule Innerpeace.Db.Repo.Migrations.CreateRegionTable do
  use Ecto.Migration

  def change do
    create table(:regions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :island_group, :string
      add :region, :string
      timestamps()
    end
  end
end
