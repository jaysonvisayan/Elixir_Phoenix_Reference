defmodule Innerpeace.Db.Repo.Migrations.CreateMemberMaintenanceUploadLog do
  use Ecto.Migration

  def change do
    create table(:member_maintenance_upload_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :member_name, :string
      add :member_id, :string
      add :employee_no, :string
      add :card_no, :string
      add :maintenance_date, :string
      add :reason, :string
      add :new_effective_date, :string
      add :new_expiry_date, :string
      add :remarks, :string
      add :status, :string
      add :member_upload_file_id, references(:member_upload_files, type: :binary_id, on_delete: :delete_all)
      add :created_by_id, references(:users, type: :binary_id)

      timestamps()
    end
    create index(:member_maintenance_upload_logs, [:member_upload_file_id])
  end
end
