defmodule Innerpeace.Db.Repo.Migrations.CreateDiagnosisLogs do
  use Ecto.Migration

  def change do
    create table(:diagnosis_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :diagnosis_id, references(:diagnoses, type: :binary_id, on_delete: :nothing)
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing)
      add :message, :text

      timestamps()
    end

    create index(:diagnosis_logs, [:diagnosis_id])
    create index(:diagnosis_logs, [:user_id])
  end
end
