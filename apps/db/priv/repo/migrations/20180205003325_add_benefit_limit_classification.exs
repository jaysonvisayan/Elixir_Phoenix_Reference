defmodule Innerpeace.Db.Repo.Migrations.AddBenefitLimitClassification do
  use Ecto.Migration

  def change do
  	alter table(:benefit_limits) do
      add :limit_classification, :string
    end
  end
end
