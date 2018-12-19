defmodule Innerpeace.Db.Repo.Migrations.FacilityPayorProcedureUploadLog do
  use Ecto.Migration

  def change do
    create table(:facility_payor_procedure_upload_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :payor_cpt_code, :string
      add :payor_cpt_name, :string
      add :provider_cpt_code, :string
      add :provider_cpt_name, :string
      add :amount, :decimal
      add :discount, :decimal
      add :start_date, :date
      add :status, :string
      add :remarks, :string
      add :room_code, :string

      add :facility_payor_procedure_upload_file_id, references(:facility_payor_procedure_upload_files, type: :binary_id, on_delete: :delete_all)
      add :created_by_id, references(:users, type: :binary_id)

      timestamps()
    end
    create index(:facility_payor_procedure_upload_logs, [:facility_payor_procedure_upload_file_id])
  end
end
