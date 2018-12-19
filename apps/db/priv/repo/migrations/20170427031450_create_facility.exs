defmodule Innerpeace.Db.Repo.Migrations.CreateFacility do
  use Ecto.Migration

  def change do
    create table(:facilities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :code, :string
      add :name, :string
      add :status, :string
      add :affiliation_date, :date
      add :disaffiliation_date, :date
      add :remarks, :string
      add :photo, :string
      add :type, :string
      add :address, :string
      add :municipality, :string
      add :province, :string
      add :region, :string
      add :country, :string
      add :postal_code, :string
      add :latitude, :string
      add :longitude, :string
      add :prescription_term, :string
      add :vat_status, :string
      add :tin_no, :string
      add :mode_of_releasing, :string
      add :bank_accnt_no, :string
      add :step, :string
      add :bank_branch_id, :string

      add :created_by, :binary_id
      add :updated_by, :binary_id

      add :bank_id, references(:banks, type: :binary_id)
      add :facility_category_id, references(:facility_categories, type: :binary_id)

      timestamps()
    end

    create unique_index(:facilities, [:code])

  end
end
