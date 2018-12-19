defmodule Innerpeace.Db.Repo.Migrations.CreatePractitionerLogs do
  use Ecto.Migration

  def change do
    create table(:practitioner_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :practitioner_id, references(:practitioners, type: :binary_id, on_delete: :nothing)
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing)
      add :message, :text

      timestamps()
    end
    create index(:practitioner_logs, [:practitioner_id])
    create index(:practitioner_logs, [:user_id])
  end
end
