defmodule Innerpeace.Db.Repo.Migrations.UpdatePfRoomConstraint do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE practitioner_facility_rooms DROP CONSTRAINT practitioner_facility_rooms_facility_room_id_fkey"

    alter table(:practitioner_facility_rooms) do
      modify(:facility_room_id, references(:facility_room_rates, type: :binary_id, on_delete: :delete_all))
    end
  end
end
