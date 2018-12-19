defmodule Innerpeace.Db.Repo.Migrations.CreatePractitionerFacilityRoom do
  use Ecto.Migration

  def change do
    create table(:practitioner_facility_rooms, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :rate, :decimal
      add :facility_room_id, references(:facility_room_rates, type: :binary_id)
      add :practitioner_facility_id, references(:practitioner_facilities, type: :binary_id)

      timestamps()
    end

    create index(:practitioner_facility_rooms, [:practitioner_facility_id])
    create index(:practitioner_facility_rooms, [:facility_room_id])
  end
end
