defmodule Innerpeace.Db.Repo.Migrations.UpdatePfPractitionerTypeConstraint do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE practitioner_facility_practitioner_types DROP CONSTRAINT practitioner_facility_practitioner_types_practitioner_facility_id_fkey"

    alter table(:practitioner_facility_practitioner_types) do
      modify(:practitioner_facility_id, references(:practitioner_facilities, type: :binary_id, on_delete: :delete_all))
    end
  end
end
