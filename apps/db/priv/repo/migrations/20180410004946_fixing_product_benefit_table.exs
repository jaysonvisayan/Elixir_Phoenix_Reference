defmodule Innerpeace.Db.Repo.Migrations.FixingProductBenefitTable do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE product_benefits DROP CONSTRAINT product_benefits_acu_product_coverage_id_fkey"
    alter table(:product_benefits) do
      remove :acu_product_coverage_id
    end

    alter table(:product_benefits) do
      add :product_coverage_id, references(:product_coverages, type: :binary_id, on_delete: :delete_all)
    end
    create index(:product_benefits, [:product_coverage_id])
  end

  def down do
    execute "ALTER TABLE product_benefits DROP CONSTRAINT product_benefits_product_coverage_id_fkey"
    alter table(:product_benefits) do
      add :acu_product_coverage_id, references(:product_coverages, type: :binary_id, on_delete: :delete_all)
    end

    alter table(:product_benefits) do
      remove :product_coverage_id
    end
  end

end
