defmodule Innerpeace.Db.Repo.Migrations.AddFacilityRoomRateInAuthRoom do
  use Ecto.Migration

  def up do
    alter table(:authorization_rooms) do
      add :facility_room_rate_id, references(:facility_room_rates, type: :binary_id, on_delete: :delete_all)
    end
  end

  def down do
    alter table(:authorization_rooms) do
      remove :facility_room_rate_id
    end
  end
end
