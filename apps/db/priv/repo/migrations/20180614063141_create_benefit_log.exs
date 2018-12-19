defmodule Innerpeace.Db.Repo.Migrations.Create_BenefitLog do
  use Ecto.Migration

  def change do
    create table(:benefit_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :benefit_id, references(:benefits, type: :binary_id, on_delete: :nothing)
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing)
      add :message, :text

      timestamps()
    end

    create index(:benefit_logs, [:benefit_id])
    create index(:benefit_logs, [:user_id])
  end
end
