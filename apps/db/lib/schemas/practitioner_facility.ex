defmodule Innerpeace.Db.Schemas.PractitionerFacility do
  @moduledoc false

  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :id,
    :practitioner,
    :payment_mode
  ]}

  schema "practitioner_facilities" do
    field :affiliation_date, Ecto.Date
    field :disaffiliation_date, Ecto.Date
    field :payment_mode, :string
    field :credit_term, :integer
    field :coordinator, :boolean
    field :consultation_fee, :decimal
    field :coordinator_fee, :decimal
    field :cp_clearance_rate, :decimal
    field :fixed, :boolean
    field :fixed_fee, :decimal
    field :step, :integer

    belongs_to :facility, Innerpeace.Db.Schemas.Facility, foreign_key: :facility_id
    belongs_to :practitioner, Innerpeace.Db.Schemas.Practitioner, foreign_key: :practitioner_id
    belongs_to :practitioner_status, Innerpeace.Db.Schemas.Dropdown, foreign_key: :pstatus_id
    belongs_to :cp_clearance, Innerpeace.Db.Schemas.Dropdown, foreign_key: :cp_clearance_id
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id
    has_many :practitioner_facility_rooms, Innerpeace.Db.Schemas.PractitionerFacilityRoom
    has_many :practitioner_facility_practitioner_types, Innerpeace.Db.Schemas.PractitionerFacilityPractitionerType
    has_one :practitioner_facility_contacts, Innerpeace.Db.Schemas.PractitionerFacilityContact
    has_many :practitioner_schedules, Innerpeace.Db.Schemas.PractitionerSchedule
    has_many :practitioner_facility_consultation_fees, Innerpeace.Db.Schemas.PractitionerFacilityConsultationFee
    many_to_many :facility_rooms, Innerpeace.Db.Schemas.FacilityRoomRate, join_through: "practitioner_facility_rooms"
    many_to_many :contacts, Innerpeace.Db.Schemas.Contact, join_through: :practitioner_facility_contacts

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :affiliation_date,
      :disaffiliation_date,
      :payment_mode,
      :credit_term,
      :coordinator,
      :consultation_fee,
      :cp_clearance_rate,
      :cp_clearance_id,
      :pstatus_id,
      :facility_id,
      :practitioner_id,
      :step,
      :created_by_id,
      :updated_by_id,
      :fixed,
      :fixed_fee,
      :coordinator_fee
    ])
    |> validate_required([
      :step,
      :updated_by_id
    ])
  end

  def step1_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :affiliation_date,
      :disaffiliation_date,
      :payment_mode,
      :credit_term,
      :coordinator,
      :consultation_fee,
      :cp_clearance_rate,
      :cp_clearance_id,
      :pstatus_id,
      :facility_id,
      :practitioner_id,
      :step,
      :created_by_id,
      :updated_by_id,
      :fixed,
      :fixed_fee,
      :coordinator_fee
    ])
    |> validate_required([
      :facility_id,
      :pstatus_id,
      :payment_mode,
      :practitioner_id,
      :step,
      :created_by_id,
      :updated_by_id
    ])
    |> unique_constraint(
      :facility_id,
      message: "Facility already exists!"
    )
  end

  def step3_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :affiliation_date,
      :disaffiliation_date,
      :payment_mode,
      :credit_term,
      :coordinator,
      :consultation_fee,
      :cp_clearance_rate,
      :cp_clearance_id,
      :pstatus_id,
      :facility_id,
      :practitioner_id,
      :step,
      :created_by_id,
      :updated_by_id,
      :fixed,
      :fixed_fee,
      :coordinator_fee
    ])
    |> validate_required([
      :coordinator
      # :consultation_fee,
    ])
  end

  def changeset_pf_seed(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :affiliation_date,
      :disaffiliation_date,
      :payment_mode,
      :step,
      :coordinator_fee,
      :consultation_fee,
      :fixed,
      :coordinator,
      :fixed_fee,
      :facility_id,
      :practitioner_id,
      :pstatus_id
    ])
  end
end
