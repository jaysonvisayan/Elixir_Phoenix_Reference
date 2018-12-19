defmodule Innerpeace.Db.Repo.Migrations.CreateProductCoverageRiskShareFacility do
  use Ecto.Migration

  def change do
    create table(:product_coverage_risk_share_facilities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_coverage_risk_share_id, references(:product_coverage_risk_shares, type: :binary_id, on_delete: :delete_all)
      add :facility_id, references(:facilities, type: :binary_id, on_delete: :delete_all)

      add :type, :string
      add :value, :string
      add :covered, :integer

      timestamps()
    end
    create index(:product_coverage_risk_share_facilities, [:product_coverage_risk_share_id])
    create index(:product_coverage_risk_share_facilities, [:facility_id])
  end
end
