defmodule Innerpeace.Db.Repo.Migrations.MemberUploadLog do
  use Ecto.Migration

  def change do
    create table(:member_upload_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :account_code, :string
      add :type, :string
      add :effectivity_date, :string
      add :expiry_date, :string
      add :first_name, :string
      add :middle_name, :string
      add :last_name, :string
      add :suffix, :string
      add :gender, :string
      add :civil_status, :string
      add :birthdate, :string
      add :employee_no, :string
      add :date_hired, :string
      add :regularization_date, :string
      add :for_card_issuance, :string
      add :email, :string
      add :mobile, :string
      add :city, :string
      add :address, :string
      add :relationship, :string
      add :product_code, :string
      add :status, :string
      add :remarks, :text

      add :member_upload_file_id, references(:member_upload_files, type: :binary_id, on_delete: :delete_all)
      add :created_by_id, references(:users, type: :binary_id)

      timestamps()
    end
    create index(:member_upload_logs, [:member_upload_file_id])
  end
end
