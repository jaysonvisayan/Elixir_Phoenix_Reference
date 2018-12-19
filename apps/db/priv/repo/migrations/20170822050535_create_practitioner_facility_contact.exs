defmodule Innerpeace.Db.Repo.Migrations.CreatePractitionerFacilityContact do
  use Ecto.Migration

  def change do
    create table(:practitioner_facility_contacts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :practitioner_facility_id, references(:practitioner_facilities, type: :binary_id, on_delete: :delete_all)
      add :contact_id, references(:contacts, type: :binary_id, on_delete: :nothing)

      timestamps()
    end

    create index(:practitioner_facility_contacts, [:practitioner_facility_id])
    create index(:practitioner_facility_contacts, [:contact_id])
  end
end
