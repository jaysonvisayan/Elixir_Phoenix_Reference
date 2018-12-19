defmodule Innerpeace.Db.Repo.Migrations.CreateFacilityRuvUploadLog do
  use Ecto.Migration

  def change do
    create table(:facility_ruv_upload_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :ruv_code, :string
      add :ruv_description, :string
      add :ruv_type, :string
      add :value, :decimal
      add :effectivity_date, :date
      add :status, :string
      add :remarks, :string

      add :facility_ruv_upload_file_id, references(:facility_ruv_upload_files, type: :binary_id, on_delete: :delete_all)
      add :created_by_id, references(:users, type: :binary_id)

      timestamps()
    end
    create index(:facility_ruv_upload_logs, [:facility_ruv_upload_file_id])
  end
end
