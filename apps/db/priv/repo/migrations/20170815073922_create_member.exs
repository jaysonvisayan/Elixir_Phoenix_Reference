defmodule Innerpeace.Db.Repo.Migrations.CreateMember do
  use Ecto.Migration

  def change do
    create unique_index(:products, [:code])
    create table(:members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :photo, :string
      add :account_code, references(:account_groups, column: :code, type: :string, on_delete: :delete_all)
      add :product_code, references(:products, column: :code, type: :string)
      add :principal_id, references(:members, type: :binary_id)
      add :type, :string
      add :effectivity_date, :date
      add :expiry_date, :date
      add :first_name, :string
      add :middle_name, :string
      add :last_name, :string
      add :suffix, :string
      add :gender, :string
      add :civil_status, :string
      add :birthdate, :date
      add :employee_no, :string
      add :date_hired, :date
      add :is_regular, :boolean, default: false
      add :regularization_date, :date
      add :tin, :string
      add :philhealth, :string
      add :for_card_issuance, :boolean, default: false
      add :email, :string
      add :email2, :string
      add :mobile, :string
      add :mobile2, :string
      add :telephone, :string
      add :fax, :string
      add :postal, :string
      add :unit_no, :string
      add :building_name, :string
      add :street_name, :string
      add :city, :string
      add :province, :string
      add :region, :string
      add :country, :string

      add :created_by_id, :binary_id
      add :updated_by_id, :binary_id

      timestamps()
    end
    create index(:members, [:account_code])
    create index(:members, [:product_code])
  end
end
