defmodule Innerpeace.Db.Repo.Migrations.CreateProductRiskShareFacility do
  use Ecto.Migration

  def change do
    create table(:product_risk_share_facilities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_risk_share_id, references(:product_risk_shares, type: :binary_id, on_delete: :nothing)
      add :facility_id, references(:facilities, type: :binary_id, on_delete: :nothing)

      add :type, :string
      add :value, :string
      add :covered, :integer

      timestamps()
    end
    create index(:product_risk_share_facilities, [:product_risk_share_id])
    create index(:product_risk_share_facilities, [:facility_id])
  end
end
