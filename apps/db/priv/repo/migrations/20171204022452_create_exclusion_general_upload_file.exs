defmodule Innerpeace.Db.Repo.Migrations.CreateExclusionGeneralUploadFile do
  use Ecto.Migration

  def change do
    create table(:exclusion_general_upload_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :remarks, :string
      add :batch_no, :string

      add :created_by_id, references(:users, type: :binary_id)

      timestamps()
    end
  end
end
