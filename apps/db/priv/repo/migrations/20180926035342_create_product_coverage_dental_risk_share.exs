defmodule Innerpeace.Db.Repo.Migrations.CreateProductCoverageDentalRiskShare do
  use Ecto.Migration

  def change do
    create table(:product_coverage_dental_risk_shares, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :asdf_type, :string
      add :asdf_amount, :decimal
      add :asdf_percentage, :decimal
      add :asdf_special_handling, :string

      add :product_coverage_id, references(:product_coverages, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end
    create index(:product_coverage_dental_risk_shares, [:product_coverage_id])
  end
end
