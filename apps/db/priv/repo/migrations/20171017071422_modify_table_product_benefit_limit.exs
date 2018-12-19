defmodule Innerpeace.Db.Repo.Migrations.ModifyTableProductBenefitLimit do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE product_benefit_limits DROP CONSTRAINT product_benefit_limits_product_benefit_id_fkey"
    execute "ALTER TABLE product_benefit_limits DROP CONSTRAINT product_benefit_limits_benefit_limit_id_fkey"

    alter table(:product_benefit_limits) do
      modify :product_benefit_id, references(:product_benefits, type: :binary_id, on_delete: :delete_all)
      modify :benefit_limit_id, references(:benefit_limits, type: :binary_id, on_delete: :delete_all)
    end
  end
end
