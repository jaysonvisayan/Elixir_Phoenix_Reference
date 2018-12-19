defmodule Innerpeace.Db.Repo.Migrations.AddRiskShareFieldsInBenefit do
  use Ecto.Migration

  def change do
    alter table(:benefits) do
      add :risk_share_type, :string
      add :risk_share_value, :decimal
      add :member_pays_handling, {:array, :string}
    end
  end
end
