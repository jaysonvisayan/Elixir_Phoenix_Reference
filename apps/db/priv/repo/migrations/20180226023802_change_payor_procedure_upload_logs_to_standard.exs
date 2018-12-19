defmodule Innerpeace.Db.Repo.Migrations.ChangePayorProcedureUploadLogsToStandard do
  use Ecto.Migration

  def change do
  	drop table(:payor_procedure_upload_logs)
    create table(:procedure_upload_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :cpt_code, :string
      add :cpt_description, :string
      add :status, :string
      add :remarks, :string

      add :procedure_id, references(:procedures, type: :binary_id)
      add :created_by_id, references(:users, type: :binary_id)

      timestamps()
    end
  end
end
