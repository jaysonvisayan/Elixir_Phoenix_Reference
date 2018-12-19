defmodule Innerpeace.Db.Repo.Migrations.CreateExclusionGeneralUploadLogs do
  use Ecto.Migration

  def change do
    create table(:exclusion_general_upload_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :payor_cpt_code, :string
      add :diagnosis_code, :string
      add :payor_cpt_status, :string
      add :diagnosis_status, :string
      add :payor_cpt_remarks, :string
      add :diagnosis_remarks, :string

      add :exclusion_general_upload_file_id, references(:exclusion_general_upload_files, type: :binary_id, on_delete: :delete_all)
      add :created_by_id, references(:users, type: :binary_id)

      timestamps()
    end
    create index(:exclusion_general_upload_logs, [:exclusion_general_upload_file_id])
  end
end
