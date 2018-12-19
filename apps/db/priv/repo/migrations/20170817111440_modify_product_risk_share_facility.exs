defmodule Innerpeace.Db.Repo.Migrations.ModifyProductRiskShareFacility do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE product_risk_share_facilities DROP CONSTRAINT product_risk_share_facilities_product_risk_share_id_fkey"
    execute "ALTER TABLE product_risk_share_facilities DROP CONSTRAINT product_risk_share_facilities_facility_id_fkey"

    alter table(:product_risk_share_facilities) do
      modify :product_risk_share_id, references(:product_risk_shares, type: :binary_id, on_delete: :delete_all)
      modify :facility_id, references(:facilities, type: :binary_id, on_delete: :delete_all)
    end
  end

end
