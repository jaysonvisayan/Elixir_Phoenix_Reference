defmodule Innerpeace.Db.Repo.Migrations.CreatePractitionerFacility do
  use Ecto.Migration

  def change do
    create table(:practitioner_facilities, primary_key: false)  do
      add :id, :binary_id, primary_key: true
      add :accreditation_date, :date
      add :disaccreditation_date, :date
      add :payment_mode, :string
      add :credit_term, :integer
      add :coordinator, :boolean
      add :consultation_fee, :decimal
      add :cp_clearance_rate, :decimal
      add :cp_clearance_id, references(:dropdowns, type: :binary_id)
      add :pstatus_id, references(:dropdowns, type: :binary_id)
      add :facility_id, references(:facilities, type: :binary_id, on_delete: :delete_all)
      add :practitioner_id, references(:practitioners, type: :binary_id, on_delete: :nothing)

      timestamps()
    end
  end
end
