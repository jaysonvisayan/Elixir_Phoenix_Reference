defmodule Innerpeace.Db.Repo.Migrations.AddLocationGroupIdInFacilityTable do
  use Ecto.Migration

  def up do
    alter table(:facilities) do
      remove :location_group

      add :location_group_id, references(:location_groups, type: :binary_id)
    end
  end

  def down do
    alter table(:facilities) do
      add :location_group, :string
    end
  end
end
