defmodule Innerpeace.Db.Repo.Migrations.AddLimitToothAndLimitQuadrantsColumnInBenefitLimits do
  use Ecto.Migration

  def change do
    alter table(:benefit_limits) do
      add :limit_tooth, :integer
      add :limit_quadrant, :integer

    end
  end
end
