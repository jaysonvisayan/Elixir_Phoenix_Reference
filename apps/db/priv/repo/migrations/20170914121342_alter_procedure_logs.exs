defmodule Innerpeace.Db.Repo.Migrations.AlterProcedureLogs do
  use Ecto.Migration

  def change do
    drop table(:procedure_logs)
    create table(:procedure_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :procedure_id, references(:procedures, type: :binary_id, on_delete: :nothing)
      add :payor_procedure_id, references(:payor_procedures, type: :binary_id, on_delete: :nothing)
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing)
      add :message, :text

      timestamps()
    end

    create index(:procedure_logs, [:payor_procedure_id])
    create index(:procedure_logs, [:procedure_id])
    create index(:procedure_logs, [:user_id])
  end
end
