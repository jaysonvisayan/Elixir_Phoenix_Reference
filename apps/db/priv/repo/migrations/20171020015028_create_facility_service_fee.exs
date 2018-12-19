defmodule Innerpeace.Db.Repo.Migrations.CreateFacilityServiceFee do
  use Ecto.Migration

  def change do
    create table(:facility_service_fees, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :facility_id, references(:facilities, type: :binary_id, on_delete: :delete_all)
      add :coverage_id, references(:coverages, type: :binary_id, on_delete: :nothing)
      add :service_type_id, references(:dropdowns, type: :binary_id)
      add :payment_mode, :string
      add :rate_fixed, :decimal
      add :rate_mdr, :integer

      timestamps()
    end
    create index(:facility_service_fees, [:facility_id])
    create index(:facility_service_fees, [:coverage_id])
  end
end
