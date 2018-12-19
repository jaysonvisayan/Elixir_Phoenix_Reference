defmodule Innerpeace.Db.Repo.Migrations.ModifyFacilityPayorProcedure do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE facility_payor_procedures DROP CONSTRAINT facility_payor_procedures_facility_id_fkey"
    execute "ALTER TABLE facility_payor_procedures DROP CONSTRAINT facility_payor_procedures_payor_procedure_id_fkey"

    drop index(:facility_payor_procedures, [:code])
  end
end
