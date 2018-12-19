defmodule Innerpeace.Db.Repo.Migrations.CreateProductCoverageRiskShare do
  use Ecto.Migration

  def change do
    create table(:product_coverage_risk_shares, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :af_type, :string
      add :af_value, :integer
      add :af_covered_percentage, :integer
      add :af_covered_amount, :decimal
      add :naf_reimbursable, :string
      add :naf_type, :string
      add :naf_value, :integer
      add :naf_covered_percentage, :integer
      add :naf_covered_amount, :decimal

      add :product_coverage_id, references(:product_coverages, type: :binary_id, on_delete: :delete_all)
      timestamps()
    end
    create index(:product_coverage_risk_shares, [:product_coverage_id])
  end
end
