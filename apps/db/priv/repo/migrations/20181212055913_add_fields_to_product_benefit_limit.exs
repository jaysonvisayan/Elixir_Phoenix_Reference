defmodule Innerpeace.Db.Repo.Migrations.AddFieldsToProductBenefitLimit do
  use Ecto.Migration

  def up do
    alter table(:product_benefit_limits) do
      add :limit_area_type, {:array, :jsonb}
      add :limit_area, {:array, :jsonb}
    end
  end

  def down do
    alter table(:product_benefit_limits) do
      remove :limit_area_type
      remove :limit_area
    end
  end

end
