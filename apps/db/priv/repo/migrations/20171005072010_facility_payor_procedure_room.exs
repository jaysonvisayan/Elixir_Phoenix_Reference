defmodule Innerpeace.Db.Repo.Migrations.FacilityPayorProcedureRoom do
  use Ecto.Migration

  def change do
    create table(:facility_payor_procedure_rooms, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :facility_payor_procedure_id, references(:facility_payor_procedures, type: :binary_id, on_delete: :delete_all)
      add :facility_room_rate_id, references(:facility_room_rates, type: :binary_id, on_delete: :delete_all)
      add :amount, :decimal
      add :discount, :decimal
      add :start_date, :date

      timestamps()
    end
    create index(:facility_payor_procedure_rooms, [:facility_payor_procedure_id, :facility_room_rate_id])
  end
end
