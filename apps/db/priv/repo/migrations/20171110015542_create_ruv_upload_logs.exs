defmodule Innerpeace.Db.Repo.Migrations.CreateRuvUploadLogs do
  use Ecto.Migration

  def change do
    create table(:ruv_upload_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :ruv_code, :string
      add :ruv_description, :string
      add :ruv_type, :string
      add :value, :decimal
      add :effectivity_date, :date
      add :status, :string
      add :remarks, :string

      add :ruv_id, references(:ruvs, type: :binary_id)
      add :created_by_id, references(:users, type: :binary_id)
      add :ruv_upload_file_id, references(:ruv_upload_files, type: :binary_id)

      timestamps()
    end
  end
end
