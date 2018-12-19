defmodule Innerpeace.Db.Repo.Migrations.AddExclusionTypeInPayorProcedureUploadLogs do
  use Ecto.Migration

  def change do
    alter table(:payor_procedure_upload_logs) do
      add :exclusion_type, :string
    end
  end
end
