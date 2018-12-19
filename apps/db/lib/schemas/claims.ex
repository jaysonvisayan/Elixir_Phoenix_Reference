defmodule Innerpeace.Db.Schemas.Claim do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "claims" do
    field :consultation_type, :string
    field :chief_complaint, :string
    field :chief_complaint_others, :string
    field :internal_remarks, :string
    field :assessed_amount, :decimal
    field :total_amount, :decimal
    field :status, :string
    field :version, :integer
    field :step, :integer
    field :admission_datetime, Ecto.DateTime
    field :discharge_datetime, Ecto.DateTime
    field :availment_type, :string
    field :number, :string
    field :reason, :string
    field :valid_until, Ecto.Date
    field :otp, :string
    field :otp_expiry, Ecto.DateTime
    field :origin, :string
    field :control_number, :string
    field :approved_datetime, Ecto.DateTime
    field :requested_datetime, Ecto.DateTime
    field :transaction_no, :string
    field :is_peme?, :boolean
    field :swipe_datetime, Ecto.DateTime
    field :batch_no, :string
    field :loe_number, :string
    field :availment_date, Ecto.Date
    field :is_claimed?, :boolean, default: false
    field :migrated, :string
    field :package_code, {:array, :string}
    field :package_name, {:array, :string}

    embeds_many :package, Innerpeace.Db.Schemas.Embedded.PackageEmbed
    embeds_many :diagnosis, Innerpeace.Db.Schemas.Embedded.DiagnosisEmbed
    embeds_many :procedure, Innerpeace.Db.Schemas.Embedded.ProcedureEmbed
    # embeds_many :diagnosis, :map
    # embeds_many :procedure, :map
    # embeds_many :physician, :map

    #for inpatient
    field :nature_of_admission, :string
    field :point_of_admission, :string
    field :senior_discount, :decimal
    field :pwd_discount, :decimal
    field :date_issued, Ecto.Date
    field :place_issued, :string
    field :or_and_dr_fee, :decimal # Operating and delivery room fee


    #Relationships
    belongs_to :member, Innerpeace.Db.Schemas.Member
    belongs_to :facility, Innerpeace.Db.Schemas.Facility
    belongs_to :coverage, Innerpeace.Db.Schemas.Coverage
    belongs_to :authorization, Innerpeace.Db.Schemas.Authorization
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id
    belongs_to :approved_by, Innerpeace.Db.Schemas.User, foreign_key: :approved_by_id
    belongs_to :edited_by, Innerpeace.Db.Schemas.User, foreign_key: :edited_by_id

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :admission_datetime,
      :discharge_datetime,
      :consultation_type,
      :chief_complaint,
      :chief_complaint_others,
      :internal_remarks,
      :assessed_amount,
      :total_amount,
      :status,
      :batch_no,
      :version,
      :member_id,
      :facility_id,
      :coverage_id,
      # :special_approval_id,
      :created_by_id,
      :updated_by_id,
      :step,
      :valid_until,
      :origin,
      :approved_by_id,
      :approved_datetime,
      :requested_datetime,
      :is_peme?,
      :edited_by_id,
      :transaction_no,
      :authorization_id,
      :number
      # :package
      # :diagnosis,
      # :procedure,
      # :physician
    ])
    |> validate_required([
      :created_by_id,
      :updated_by_id
    ])
  end

  def changeset_constraints(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :coverage_id,
      :facility_id,
      :member_id
    ])
    |> validate_required([
      :coverage_id,
      :facility_id,
      :member_id
    ])
  end

  def changeset_migrated(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :migrated
    ])
    |> validate_required([
      :migrated
    ])
  end
end
