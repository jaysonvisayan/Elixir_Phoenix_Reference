defmodule Innerpeace.Db.Repo.Migrations.ModifyProductBenefitTable do
  use Ecto.Migration

  def change do

    execute "ALTER TABLE product_benefits DROP CONSTRAINT product_benefits_benefit_id_fkey"
    execute "ALTER TABLE product_benefits DROP CONSTRAINT product_benefits_product_id_fkey"

    alter table(:product_benefits) do
      modify :benefit_id, references(:benefits, type: :binary_id, on_delete: :delete_all)
      modify :product_id, references(:products, type: :binary_id, on_delete: :delete_all)
    end
  end
end
