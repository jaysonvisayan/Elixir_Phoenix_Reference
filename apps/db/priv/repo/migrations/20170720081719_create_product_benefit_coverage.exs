defmodule Innerpeace.Db.Repo.Migrations.CreateProductBenefitCoverage do
  use Ecto.Migration

  def change do
  create table(:product_benefit_coverages, primary_key: false) do
    add :id, :binary_id, primary_key: true
    add :product_benefit_id, references(:product_benefits, type: :binary_id, on_delete: :nothing)
    add :coverage_id, references(:coverages, type: :binary_id, on_delete: :nothing)

    timestamps()
  end
  create index(:product_benefit_coverages, [:product_benefit_id])
  create index(:product_benefit_coverages, [:coverage_id])
  end
end

