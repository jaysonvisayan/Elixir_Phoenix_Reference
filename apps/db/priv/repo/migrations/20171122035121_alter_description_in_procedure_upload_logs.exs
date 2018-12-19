defmodule Innerpeace.Db.Repo.Migrations.AlterDescriptionInProcedureUploadLogs do
  use Ecto.Migration

  def change do
    alter table(:payor_procedure_upload_logs) do
      modify :standard_cpt_description, :text
      modify :payor_cpt_description, :text
    end
  end
end
