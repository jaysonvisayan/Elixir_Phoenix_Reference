defmodule Innerpeace.Db.Repo.Migrations.AlterPayorProcedureUploadLogs do
  use Ecto.Migration

  def change do
    alter table(:payor_procedure_upload_logs) do
      add :payor_procedure_upload_file_id, references(:payor_procedure_upload_files, type: :binary_id)
    end
  end
end
