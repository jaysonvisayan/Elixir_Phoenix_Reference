defmodule Innerpeace.Db.Repo.Migrations.CreateRoomLogs do
  use Ecto.Migration

  def change do
    create table(:room_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :room_id, references(:rooms, type: :binary_id, on_delete: :nothing)
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing)
      add :message, :text

      timestamps()
    end
    create index(:room_logs, [:room_id])
    create index(:room_logs, [:user_id])
  end

end
