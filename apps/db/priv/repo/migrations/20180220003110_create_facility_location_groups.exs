defmodule Innerpeace.Db.Repo.Migrations.CreateFacilityLocationGroups do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE facilities DROP CONSTRAINT facilities_location_group_id_fkey"

    alter table(:facilities) do
      remove :location_group_id
    end

    create table(:facility_location_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :facility_id, references(:facilities, type: :binary_id)
      add :location_group_id, references(:location_groups, type: :binary_id)

      timestamps()
    end
  end

  def down do
    alter table(:facilities) do
      add :location_group_id, references(:location_groups, type: :binary_id)
    end
  end
end
