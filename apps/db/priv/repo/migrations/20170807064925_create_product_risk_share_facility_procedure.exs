defmodule Innerpeace.Db.Repo.Migrations.CreateProductRiskShareFacilityProcedure do
  use Ecto.Migration

  def change do
    create table(:product_risk_share_facility_procedures, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_risk_share_facility_id, references(:product_risk_share_facilities, type: :binary_id, on_delete: :nothing)
      add :procedure_id, references(:procedures, type: :binary_id, on_delete: :nothing)

      add :rs_type, :string
      add :rs_value, :string
      add :rs_covered, :integer

      timestamps()
    end
    create index(:product_risk_share_facility_procedures, [:product_risk_share_facility_id])
    create index(:product_risk_share_facility_procedures, [:procedure_id])
  end
end
