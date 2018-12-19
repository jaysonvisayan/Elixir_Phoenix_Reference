defmodule Innerpeace.Db.Repo.Migrations.CreateClaim do
  use Ecto.Migration

  def change do
    create table(:claims, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :consultation_type, :string
      add :chief_complaint, :string
      add :chief_complaint_others, :string
      add :internal_remarks, :string
      add :assessed_amount, :decimal
      add :total_amount, :decimal
      add :status, :string
      add :version, :integer
      add :step, :integer
      add :admission_datetime, :datetime
      add :discharge_datetime, :datetime
      add :availment_type, :string
      add :number, :string
      add :reason, :string
      add :valid_until, :date
      add :otp, :string
      add :otp_expiry, :date
      add :origin, :string
      add :control_number, :string
      add :approved_datetime, :datetime
      add :requested_datetime, :datetime
      add :transaction_no, :string
      add :is_peme?, :boolean
      add :swipe_datetime, :datetime
      add :loe_number, :string
      add :availment_date, :date
      add :is_claimed?, :boolean, default: false
      add :diagnosis, {:array, :jsonb}
      add :physician, {:array, :jsonb}
      add :procedure, {:array, :jsonb}
      add :package, {:array, :jsonb}
      add :authorization_id, references(:authorizations, type: :binary_id)

      add :migrated, :string

      #for inpatient

      add :nature_of_admission, :string
      add :point_of_admission, :string
      add :senior_discount, :decimal
      add :pwd_discount, :decimal
      add :date_issued, :date
      add :place_issued, :string
      add :or_and_dr_fee, :decimal # Operating and delivery room fee
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      timestamps()

      add :batch_no, :string
      add :approved_by_id, references(:users, type: :binary_id)
      add :edited_by_id, references(:users, type: :binary_id)
      add :member_id, references(:members, type: :binary_id)
      add :facility_id, references(:facilities, type: :binary_id)
      add :coverage_id, references(:coverages, type: :binary_id)
      add :special_approval_id, references(:dropdowns, type: :binary_id)
    end
  end
end
