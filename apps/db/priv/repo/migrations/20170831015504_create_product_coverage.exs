defmodule Innerpeace.Db.Repo.Migrations.CreateProductCoverage do
  use Ecto.Migration

  def change do
    create table(:product_coverages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_id, references(:products, type: :binary_id, on_delete: :delete_all)
      add :coverage_id, references(:coverages, type: :binary_id, on_delete: :delete_all)

      ### for facility access
      add :type, :string
      ### for condition
      add :funding_arrangement, :string
      add :acu_product_benefit_id, references(:product_benefits, type: :binary_id, on_delete: :delete_all)
      timestamps()
    end
    create index(:product_coverages, [:product_id])
    create index(:product_coverages, [:coverage_id])
  end
end
