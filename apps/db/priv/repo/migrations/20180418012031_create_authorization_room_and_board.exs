defmodule Innerpeace.Db.Repo.Migrations.CreateAuthorizationRoomAndBoard do
  use Ecto.Migration

  def change do
    create table(:authorization_rooms, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :admission_date, :date
      add :admission_time, :time
      add :transfer_date, :date
      add :transfer_time, :time
      add :for_isolation, :boolean

      add :authorization_id, references(:authorizations, type: :binary_id, on_delete: :delete_all)
      add :room_id, references(:rooms, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end
  end
end
