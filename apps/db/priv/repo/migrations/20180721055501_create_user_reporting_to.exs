defmodule Innerpeace.Db.Repo.Migrations.CreateUserReportingTo do
  use Ecto.Migration

  def change do
    create table(:user_reporting_to, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id)
      add :lead_id, references(:users, type: :binary_id)

      timestamps()
    end
    create unique_index(:user_reporting_to, [:user_id, :lead_id])
  end
end
