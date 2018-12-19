defmodule Innerpeace.Db.Repo.Migrations.ChangeRoomNumberDatatype do
  use Ecto.Migration

  def change do
   alter table(:facility_room_rates) do
      modify :facility_room_number, :string
    end

  end
end
