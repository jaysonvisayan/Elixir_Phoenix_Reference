defmodule Innerpeace.Db.Repo.Migrations.AddFacilityIdInUser do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :facility_id, references(:facilities, type: :binary_id)
    end
  end

  def down do
    alter table(:users) do
      remove :facility_id
    end
  end
end
