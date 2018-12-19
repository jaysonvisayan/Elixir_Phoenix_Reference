defmodule Innerpeace.Db.Repo.Migrations.AddProcedureUploadFileIdToProcedureUploadLogs do
  use Ecto.Migration

  def change do
    alter table(:procedure_upload_logs) do
      add :procedure_upload_file_id, references(:procedure_upload_files, type: :binary_id)
    end
  end
end
