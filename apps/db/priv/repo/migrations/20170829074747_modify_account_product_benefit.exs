defmodule Innerpeace.Db.Repo.Migrations.ModifyAccountProductBenefit do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE account_product_benefits DROP CONSTRAINT account_product_benefits_product_benefit_id_fkey"

    alter table(:account_product_benefits) do
      modify :product_benefit_id, references(:product_benefits, type: :binary_id, on_delete: :delete_all)
    end

  end
end
