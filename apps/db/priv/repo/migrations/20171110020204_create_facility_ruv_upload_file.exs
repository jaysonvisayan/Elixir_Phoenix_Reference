defmodule Innerpeace.Db.Repo.Migrations.CreateFacilityRuvUploadFile do
  use Ecto.Migration

  def change do
    create table(:facility_ruv_upload_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :remarks, :string
      add :batch_no, :string

      add :facility_id, references(:facilities, type: :binary_id, on_delete: :delete_all)
      add :created_by_id, references(:users, type: :binary_id)

      timestamps()
    end
    create index(:facility_ruv_upload_files, [:facility_id])
  end
end
