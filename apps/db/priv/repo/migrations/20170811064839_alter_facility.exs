defmodule Innerpeace.Db.Repo.Migrations.AlterFacility do
  use Ecto.Migration

  def change do
    alter table(:facilities) do
      remove :remarks
      remove :address
      remove :municipality
      remove :tin_no
      remove :bank_accnt_no
      remove :bank_branch_id
      remove :prescription_term
      remove :created_by
      remove :updated_by
      remove :step
      remove :type
      remove :photo

      add :license_name, :string
      add :phic_accreditation_from, :date
      add :phic_accreditation_to, :date
      add :phic_accreditation_no, :string
      add :phone_no, :string
      add :email_address, :string
      add :tin, :string
      add :prescription_clause, :string
      add :credit_term, :integer
      add :credit_limit, :integer
      add :mode_of_payment, :string
      add :no_of_beds, :string
      add :bond, :decimal
      add :prescription_term, :integer
      add :created_by_id, :binary_id
      add :updated_by_id, :binary_id
      add :step, :integer
      add :logo, :string
      add :city, :string
      add :line_1, :string
      add :line_2, :string
      add :fcategory_id, references(:dropdowns, type: :binary_id)
      add :ftype_id, references(:dropdowns, type: :binary_id)
      add :vat_status_id, references(:dropdowns, type: :binary_id)
      add :prescription_clause_id, references(:dropdowns, type: :binary_id)
      add :releasing_mode_id, references(:dropdowns, type: :binary_id)
      add :payment_mode_id, references(:dropdowns, type: :binary_id)
    end
  end
end
