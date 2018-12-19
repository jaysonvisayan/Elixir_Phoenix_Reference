defmodule Innerpeace.Db.Repo.Migrations.CreateFacilityUploadLog do
  use Ecto.Migration

  def change do
    create table(:facility_upload_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :facility_code, :string
      add :facility_name, :string
      add :status, :string
      add :remarks, :string

      add :facility_id, references(:facilities, type: :binary_id)
      add :created_by_id, references(:users, type: :binary_id)
	    add :facility_upload_file_id, references(:facility_upload_files, type: :binary_id)

      timestamps()
    end
  end
end
