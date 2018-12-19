defmodule Innerpeace.Db.Repo.Migrations.CreateMemberLogs do
  use Ecto.Migration

  def change do
   create table(:member_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :member_id, references(:members, type: :binary_id, on_delete: :nothing)
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing)
      add :message, :text

      timestamps()
    end
    create index(:member_logs, [:member_id])
    create index(:member_logs, [:user_id])

  end
end
