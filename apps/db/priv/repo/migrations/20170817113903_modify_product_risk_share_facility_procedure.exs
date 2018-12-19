defmodule Innerpeace.Db.Repo.Migrations.ModifyProductRiskShareFacilityProcedure do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE product_risk_share_facility_procedures DROP CONSTRAINT product_risk_share_facility_procedures_product_risk_share_facility_id_fkey"
    execute "ALTER TABLE product_risk_share_facility_procedures DROP CONSTRAINT product_risk_share_facility_procedures_procedure_id_fkey"

    alter table(:product_risk_share_facility_procedures) do
      modify :product_risk_share_facility_id, references(:product_risk_share_facilities, type: :binary_id, on_delete: :delete_all)
      modify :procedure_id, references(:procedures, type: :binary_id, on_delete: :delete_all)
    end
  end
end
