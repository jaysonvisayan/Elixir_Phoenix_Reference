defmodule Innerpeace.Db.Repo.Migrations.CreatePractitionerFacilityConsultationFees do
  use Ecto.Migration

  def change do
    create table(:practitioner_facility_consultation_fees, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :fee, :decimal
      add :practitioner_facility_id, references(:practitioner_facilities, type: :binary_id)
      add :practitioner_specialization_id, references(:practitioner_specializations, type: :binary_id)

      timestamps()
    end
  end
end
