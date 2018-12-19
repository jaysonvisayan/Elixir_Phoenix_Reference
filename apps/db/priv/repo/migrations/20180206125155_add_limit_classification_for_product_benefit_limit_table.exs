defmodule Innerpeace.Db.Repo.Migrations.AddLimitClassificationForProductBenefitLimitTable do
  use Ecto.Migration

  def change do
  	alter table(:product_benefit_limits) do
      add :limit_classification, :string
    end
  end
end
