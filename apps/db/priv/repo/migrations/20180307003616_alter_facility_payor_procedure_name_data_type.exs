defmodule Innerpeace.Db.Repo.Migrations.AlterFacilityPayorProcedureNameDataType do
  use Ecto.Migration

  def up do
    alter table(:facility_payor_procedures) do
      modify :name, :text
    end

    alter table(:facility_payor_procedure_upload_logs) do
      modify :provider_cpt_name, :text
    end
  end

  def down do
    alter table(:facility_payor_procedures) do
      modify :name, :string
    end

    alter table(:facility_payor_procedure_upload_logs) do
      modify :provider_cpt_name, :string
    end
  end
end
