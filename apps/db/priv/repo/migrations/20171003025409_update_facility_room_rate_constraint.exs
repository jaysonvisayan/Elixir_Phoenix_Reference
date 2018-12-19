defmodule Innerpeace.Db.Repo.Migrations.UpdateFacilityRoomRateConstraint do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE facility_room_rates DROP CONSTRAINT facility_room_rates_facility_id_fkey"

    alter table(:facility_room_rates) do
      modify(:facility_id, references(:facilities, type: :binary_id, on_delete: :delete_all))
    end
  end
end
