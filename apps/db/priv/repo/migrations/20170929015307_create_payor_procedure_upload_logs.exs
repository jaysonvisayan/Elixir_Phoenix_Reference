defmodule Innerpeace.Db.Repo.Migrations.CreatePayorProcedureUploadLogs do
  use Ecto.Migration

  def change do
    create table(:payor_procedure_upload_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :standard_cpt_code, :string
      add :standard_cpt_description, :string
      add :payor_cpt_code, :string
      add :payor_cpt_description, :string
      add :status, :string
      add :remarks, :string

      add :payor_procedure_id, references(:payor_procedures, type: :binary_id)
      add :created_by_id, references(:users, type: :binary_id)

      timestamps()
    end
  end
end
