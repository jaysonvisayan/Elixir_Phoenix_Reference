defmodule Innerpeace.Db.Repo.Migrations.CreateCoverageApprovalLimitAmount do
  use Ecto.Migration

  def change do
    create table(:coverage_approval_limit_amounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :coverage_id, references(:coverages, type: :binary_id, on_delete: :nothing)
      add :role_id, references(:roles, type: :binary_id, on_delete: :nothing)
      add :approval_limit_amount, :decimal

      timestamps()
    end

    create index(:coverage_approval_limit_amounts, [:coverage_id])
    create index(:coverage_approval_limit_amounts, [:role_id])
  end
end
