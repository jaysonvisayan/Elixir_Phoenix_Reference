defmodule Innerpeace.Db.Repo.Migrations.CreateTableSchedulerLogs do
  use Ecto.Migration

  def change do
    create table(:scheduler_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :message, :string
      add :name, :string

      timestamps()
    end
  end
end
