defmodule Innerpeace.Db.Repo.Migrations.CreateFacilityRoomRates do
  use Ecto.Migration

  def change do
    create table(:facility_room_rates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :facility_id, references(:facilities, type: :binary_id)
      add :room_id, references(:rooms, type: :binary_id)
      add :facility_room_type, :string
      add :facility_room_rate, :string
      timestamps()
    end
       create index(:facility_room_rates, [:facility_id, :room_id])
  end
end
