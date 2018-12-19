defmodule Innerpeace.Db.Repo.Migrations.ChangePayorProcedureUploadFilesToStandard do
  use Ecto.Migration

  def change do
  	drop table(:payor_procedure_upload_files)

    create table(:procedure_upload_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :remarks, :string

      add :created_by_id, references(:users, type: :binary_id)

      timestamps()
    end
  end
end
