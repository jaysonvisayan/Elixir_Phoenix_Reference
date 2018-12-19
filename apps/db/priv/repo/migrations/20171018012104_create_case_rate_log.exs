defmodule Innerpeace.Db.Repo.Migrations.CreateCaseRateLog do
  use Ecto.Migration

  def change do
  	create table(:case_rate_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :case_rate_id, references(:case_rates, type: :binary_id, on_delete: :nothing)
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing)
      add :message, :text

      timestamps()
  	end

  	create index(:case_rate_logs, [:case_rate_id])
    create index(:case_rate_logs, [:user_id])

  end
end
