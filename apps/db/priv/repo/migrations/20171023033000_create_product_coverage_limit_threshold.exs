defmodule Innerpeace.Db.Repo.Migrations.CreateProductCoverageLimitThreshold do
  use Ecto.Migration

  def change do
    create table(:product_coverage_limit_thresholds, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_coverage_id, references(:product_coverages, type: :binary_id, on_delete: :delete_all)
      add :limit_threshold, :decimal

      timestamps()
    end

    create index(:product_coverage_limit_thresholds, [:product_coverage_id])
  end
end
