defmodule Innerpeace.Db.Repo.Migrations.CreateProductCoverageLimitThresholdFacility do
  use Ecto.Migration

  def change do
    create table(:product_coverage_limit_threshold_facilities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_coverage_limit_threshold_id, references(:product_coverage_limit_thresholds, type: :binary_id, on_delete: :delete_all)
      add :facility_id, references(:facilities, type: :binary_id, on_delete: :delete_all)
      add :limit_threshold, :decimal

      timestamps()
    end

    create index(:product_coverage_limit_threshold_facilities, [:product_coverage_limit_threshold_id])
  end
end
