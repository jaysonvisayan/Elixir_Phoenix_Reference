defmodule Innerpeace.Db.Repo.Migrations.CreateProcedureLogs do
  use Ecto.Migration

   def change do
    create table(:procedure_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :payor_procedure_id, references(:payor_procedures, type: :binary_id, on_delete: :nothing)
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing)
      add :message, :text

      timestamps()
   end

    create index(:procedure_logs, [:payor_procedure_id])
    create index(:procedure_logs, [:user_id])

  end
end
