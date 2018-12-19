defmodule Innerpeace.Db.Repo.Migrations.CreateProductCoverageRiskShareFacilityProcedure do
  use Ecto.Migration

  def change do
    create table(:product_coverage_risk_share_facility_procedures, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_coverage_risk_share_facility_id, references(:product_coverage_risk_share_facilities, type: :binary_id, on_delete: :delete_all)
      add :procedure_id, references(:procedures, type: :binary_id, on_delete: :delete_all)

      add :type, :string
      add :value, :string
      add :covered, :integer

      timestamps()
    end
    create index(:product_coverage_risk_share_facility_procedures, [:product_coverage_risk_share_facility_id])
    create index(:product_coverage_risk_share_facility_procedures, [:procedure_id])
  end
end
