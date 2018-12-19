defmodule Innerpeace.Db.Repo.Migrations.AddFieldFacilityRoomRate do
  use Ecto.Migration

  def change do
    alter table(:facility_room_rates) do
      add :facility_ruv_rate, :decimal
      add :facility_room_number, :integer
    end
  end
end
