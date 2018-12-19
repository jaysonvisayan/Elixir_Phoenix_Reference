defmodule Innerpeace.Db.Repo.Migrations.CreateFacilityPayorProcedure do
  use Ecto.Migration

  def change do
    create table(:facility_payor_procedures, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :code, :string
      add :name, :string
      add :amount, :decimal
      add :start_date, :date
      add :facility_id, references(:facilities, type: :binary_id, on_delete: :delete_all)
      add :payor_procedure_id, references(:payor_procedures, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:facility_payor_procedures, [:code])
    create index(:facility_payor_procedures, [:facility_id])
    create index(:facility_payor_procedures, [:payor_procedure_id])
  end
end
