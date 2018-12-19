defmodule Innerpeace.Db.Repo.Migrations.CreateTableLocationGroupRegions do
  use Ecto.Migration

  def change do
    create table(:location_group_regions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :location_group_id, references(:location_groups, type: :binary_id)
      add :region_name, :string
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      timestamps()
    end
  end
end
