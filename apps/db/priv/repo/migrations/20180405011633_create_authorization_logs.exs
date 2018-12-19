defmodule Innerpeace.Db.Repo.Migrations.CreateAuthorizationLogs do
  use Ecto.Migration

  def change do
   create table(:authorization_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :authorization_id, references(:authorizations, type: :binary_id, on_delete: :nothing)
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing)
      add :message, :text

      timestamps()
    end
    create index(:authorization_logs, [:authorization_id])
    create index(:authorization_logs, [:user_id])

  end
end
