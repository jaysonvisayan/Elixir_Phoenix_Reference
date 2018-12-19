defmodule Innerpeace.Db.Repo.Migrations.CreateProductCoverageFacility do
  use Ecto.Migration

  def change do
    create table(:product_coverage_facilities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_coverage_id, references(:product_coverages, type: :binary_id, on_delete: :delete_all)
      add :facility_id, references(:facilities, type: :binary_id, on_delete: :delete_all)
      timestamps()
    end
    create index(:product_coverage_facilities, [:product_coverage_id])
    create index(:product_coverage_facilities, [:facility_id])
  end
end
