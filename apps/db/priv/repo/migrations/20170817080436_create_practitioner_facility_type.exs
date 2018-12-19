defmodule Innerpeace.Db.Repo.Migrations.CreatePractitionerFacilityType do
  use Ecto.Migration

  def change do
    create table(:practitioner_facility_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :fp_id, references(:practitioner_facilities, type: :binary_id)

      timestamps()
    end
  end
end
