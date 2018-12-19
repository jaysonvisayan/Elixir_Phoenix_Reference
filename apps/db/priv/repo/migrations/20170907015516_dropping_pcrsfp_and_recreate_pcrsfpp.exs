defmodule Innerpeace.Db.Repo.Migrations.DroppingPcrsfpAndRecreatePcrsfpp do
  use Ecto.Migration

  def change do
    drop table(:product_coverage_risk_share_facility_procedures)

    create table(:product_coverage_risk_share_facility_payor_procedures, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_coverage_risk_share_facility_id, references(:product_coverage_risk_share_facilities, type: :binary_id, on_delete: :delete_all)
      add :facility_payor_procedure_id, references(:facility_payor_procedures, type: :binary_id, on_delete: :delete_all)

      add :type, :string
      add :value, :string
      add :covered, :integer

      timestamps()
    end
    create index(:product_coverage_risk_share_facility_payor_procedures, [:product_coverage_risk_share_facility_id])
    create index(:product_coverage_risk_share_facility_payor_procedures, [:facility_payor_procedure_id])

  end
end
