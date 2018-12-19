defmodule Innerpeace.Db.Repo.Migrations.AlterPractitionerFacilityType do
  use Ecto.Migration

  def change do
    drop table(:practitioner_facility_types)

    create table(:practitioner_facility_practitioner_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :practitioner_facility_id, references(:practitioner_facilities, type: :binary_id)

      timestamps()
    end
  end
end
