defmodule Innerpeace.Db.Repo.Migrations.AlterRiskShare do
  use Ecto.Migration

  def change do
    alter table(:product_coverage_risk_shares) do
      add :af_value_percentage, :integer
      add :af_value_amount, :decimal
      add :naf_value_percentage, :integer
      add :naf_value_amount, :decimal
    end
    alter table(:product_coverage_risk_share_facilities) do
      add :value_percentage, :integer
      add :value_amount, :decimal
    end
    alter table(:product_coverage_risk_share_facility_payor_procedures) do
      add :value_percentage, :integer
      add :value_amount, :decimal
    end
  end
end
