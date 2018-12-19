defmodule Innerpeace.Db.Repo.Migrations.UpdatePractitionerFacilityRelationship do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE practitioner_facilities DROP CONSTRAINT practitioner_facilities_facility_id_fkey"

    alter table(:practitioner_facilities) do
      modify(:facility_id, references(:facilities, type: :binary_id, on_delete: :nothing))
    end
  end
end
