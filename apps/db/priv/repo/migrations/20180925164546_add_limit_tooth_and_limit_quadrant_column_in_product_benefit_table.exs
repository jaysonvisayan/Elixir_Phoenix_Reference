defmodule Innerpeace.Db.Repo.Migrations.AddLimitToothAndLimitQuadrantColumnInProductBenefitTable do
  use Ecto.Migration

  def change do
    alter table(:product_benefit_limits) do
      add :limit_tooth, :integer
      add :limit_quadrant, :integer

    end
  end
end
