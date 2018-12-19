defmodule Innerpeace.Db.Repo.Migrations.DropUniqueIndexTypeInRooms do
  use Ecto.Migration

  def change do
    drop unique_index(:rooms, [:type])
  end
end
