defmodule Innerpeace.Db.Repo.Migrations.CreateAccountCoverageFund do
  use Ecto.Migration

  def change do
    create table(:account_group_coverage_funds, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_group_id, references(:account_groups, type: :binary_id)
      add :coverage_id, references(:coverages, type: :binary_id)
      add :revolving_fund, :decimal
      add :replenish_threshold, :decimal

      timestamps()
    end
  end
end
