defmodule Innerpeace.Db.Repo.Migrations.CreateRuvLogs do
  use Ecto.Migration

  def change do
    create table(:ruv_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ruv_id, references(:ruvs, type: :binary_id, on_delete: :delete_all)
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing)
      add :message, :text

      timestamps()
    end

    create index(:ruv_logs, [:ruv_id])
    create index(:ruv_logs, [:user_id])
  end
end
