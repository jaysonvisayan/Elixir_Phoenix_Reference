defmodule Innerpeace.Db.Repo.Migrations.CreateProductRiskShare do
  use Ecto.Migration

  def change do
    create table(:product_risk_shares, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_id, references(:products, type: :binary_id, on_delete: :nothing)
      add :coverage_id, references(:coverages, type: :binary_id, on_delete: :nothing)

      add :fund, :string
      add :af_type, :string
      add :af_value, :integer
      add :af_covered, :integer
      add :naf_reimbursable, :string
      add :naf_type, :string
      add :naf_value, :integer
      add :naf_covered, :integer

      timestamps()
    end
    create index(:product_risk_shares, [:product_id])
    create index(:product_risk_shares, [:coverage_id])
  end
end
