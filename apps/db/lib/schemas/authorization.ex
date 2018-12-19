defmodule Innerpeace.Db.Schemas.Authorization do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "authorizations" do
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
    field :loe_number, :string
    field :availment_date, Ecto.Date
    field :is_claimed?, :boolean, default: false
    field :requested_by, :string
    field :facial_image, :string

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
    belongs_to :special_approval, Innerpeace.Db.Schemas.Dropdown, foreign_key: :special_approval_id
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id
    has_many :authorization_diagnosis, Innerpeace.Db.Schemas.AuthorizationDiagnosis, on_delete: :delete_all
    has_many :authorization_files, Innerpeace.Db.Schemas.AuthorizationFile, on_delete: :delete_all
    has_many :authorization_practitioners, Innerpeace.Db.Schemas.AuthorizationPractitioner, on_delete: :delete_all
    has_many :authorization_practitioner_specializations,
      Innerpeace.Db.Schemas.AuthorizationPractitionerSpecialization, on_delete: :delete_all
    has_many :authorization_procedure_diagnoses,
      Innerpeace.Db.Schemas.AuthorizationProcedureDiagnosis, on_delete: :delete_all
    has_many :authorization_facility_ruvs, Innerpeace.Db.Schemas.AuthorizationRUV, on_delete: :delete_all
    has_one :authorization_amounts, Innerpeace.Db.Schemas.AuthorizationAmount, on_delete: :delete_all
    belongs_to :room, Innerpeace.Db.Schemas.Room
    has_many :authorization_benefit_packages, Innerpeace.Db.Schemas.AuthorizationBenefitPackage
    has_many :batch_authorizations, Innerpeace.Db.Schemas.BatchAuthorization, on_delete: :delete_all
    has_many :logs, Innerpeace.Db.Schemas.AuthorizationLog, on_delete: :delete_all
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
      :version,
      :member_id,
      :facility_id,
      :coverage_id,
      :special_approval_id,
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
      :number,
      :requested_by
    ])
    |> validate_required([
      :created_by_id,
      :step,
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

  def step2_changeset(struct, params) do
    struct
    |> cast(params, [
      :consultation_type,
      :chief_complaint,
      :chief_complaint_others,
      :internal_remarks,
      :assessed_amount,
      :total_amount,
      :status,
      :version,
      :member_id,
      :facility_id,
      :coverage_id,
      :special_approval_id,
      :created_by_id,
      :updated_by_id,
      :step,
      :valid_until
    ])
    |> validate_required([
      :facility_id,
      :step,
      :updated_by_id
    ])
  end

  def step3_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :consultation_type,
      :chief_complaint,
      :chief_complaint_others,
      :internal_remarks,
      :assessed_amount,
      :total_amount,
      :status,
      :version,
      :member_id,
      :facility_id,
      :coverage_id,
      :special_approval_id,
      :created_by_id,
      :updated_by_id,
      :step,
      :valid_until
    ])
    |> validate_required([
      :coverage_id
    ])

  end

  def step4_consult_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :admission_datetime,
      :consultation_type,
      :chief_complaint,
      :chief_complaint_others,
      :internal_remarks,
      :assessed_amount,
      :total_amount,
      :status,
      :version,
      :member_id,
      :facility_id,
      :coverage_id,
      :special_approval_id,
      :created_by_id,
      :updated_by_id,
      :step,
      :valid_until,
      :approved_by_id,
      :approved_datetime,
      :requested_datetime,
      :origin,
      :is_peme?,
      :edited_by_id
    ])
    |> validate_required([
      :consultation_type,
      :member_id,
      :facility_id,
      :coverage_id
    ])
  end

  def step4_consult_save_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :admission_datetime,
      :consultation_type,
      :chief_complaint,
      :chief_complaint_others,
      :internal_remarks,
      :assessed_amount,
      :total_amount,
      :special_approval_id,
      :status,
      :version,
      :member_id,
      :facility_id,
      :coverage_id,
      :created_by_id,
      :updated_by_id,
      :step,
      :origin,
      :edited_by_id,
      :senior_discount,
      :pwd_discount,
      :date_issued,
      :place_issued
    ])
    |> validate_required([
      :member_id,
      :facility_id,
      :coverage_id
    ])
  end

  def consult_approve_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :admission_datetime,
      :chief_complaint,
      :internal_remarks,
      :assessed_amount,
      :total_amount,
      :status,
      :version,
      :member_id,
      :facility_id,
      :coverage_id,
      :special_approval_id,
      :created_by_id,
      :updated_by_id,
      :step,
      :valid_until,
      :approved_by_id,
      :approved_datetime,
      :requested_datetime,
      :origin,
      :edited_by_id
    ])
    |> validate_required([
      :member_id,
      :facility_id,
      :coverage_id
    ])
    |> put_change(:number, random_loa_number())
    |> put_change(:control_number, random_loa_number())
  end

  def op_laboratory_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :admission_datetime,
      :chief_complaint,
      :internal_remarks,
      :assessed_amount,
      :total_amount,
      :status,
      :version,
      :member_id,
      :facility_id,
      :coverage_id,
      :special_approval_id,
      :created_by_id,
      :updated_by_id,
      :step,
      :valid_until,
      :approved_by_id,
      :approved_datetime,
      :origin,
      :edited_by_id
    ])
    |> validate_required([
      :member_id,
      :facility_id,
      :coverage_id
    ])
    |> put_change(:number, random_loa_number())
  end

  def emergency_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :admission_datetime,
      :chief_complaint,
      :internal_remarks,
      :assessed_amount,
      :total_amount,
      :status,
      :version,
      :member_id,
      :facility_id,
      :coverage_id,
      :special_approval_id,
      :created_by_id,
      :updated_by_id,
      :step,
      :valid_until,
      :approved_by_id,
      :approved_datetime,
      :edited_by_id
    ])
    |> validate_required([
      :member_id,
      :facility_id,
      :coverage_id
    ])
  end

  def step4_emergency_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :admission_datetime,
      :chief_complaint,
      :internal_remarks,
      :assessed_amount,
      :total_amount,
      :status,
      :version,
      :member_id,
      :facility_id,
      :coverage_id,
      :special_approval_id,
      :created_by_id,
      :updated_by_id,
      :step,
      :valid_until,
      :approved_by_id,
      :approved_datetime,
      :edited_by_id
    ])
    |> validate_required([
      :member_id,
      :facility_id,
      :coverage_id
    ])
    |> put_change(:number, random_loa_number())
  end

  # Validators
  def op_consult_validator_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :consultation_type,
      :chief_complaint,
      :chief_complaint_others,
      :internal_remarks,
      :member_id,
      :facility_id,
      :edited_by_id
    ])
    |> validate_required([
      :member_id,
      :facility_id
    ])
  end

  # MemberLink Start
  def op_lab_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :facility_id,
      :admission_datetime,
      :availment_type,
      :chief_complaint,
      :coverage_id,
      :member_id,
      :created_by_id,
      :updated_by_id,
      :consultation_type,
      :step,
      :valid_until,
      :approved_by_id,
      :approved_datetime,
      :edited_by_id
    ])
    |> validate_required([
      :facility_id,
      :admission_datetime,
      :availment_type,
      :chief_complaint,
      :coverage_id,
      :member_id
    ])
    |> put_change(:number, random_loa_number())
  end

  def op_consult_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :consultation_type,
      :facility_id,
      :admission_datetime,
      :chief_complaint,
      :chief_complaint_others,
      :coverage_id,
      :member_id,
      :step,
      :status,
      :created_by_id,
      :valid_until,
      :approved_by_id,
      :approved_datetime,
      :requested_datetime,
      :origin,
      :version,
      :edited_by_id
    ])
    |> validate_required([
      :facility_id,
      :admission_datetime,
      :chief_complaint,
      :coverage_id,
      :member_id,
    ])
  end

  def reason_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :reason,
      :status
    ])
    |> validate_required([
      :reason,
      :status
    ])
  end

  def random_loa_number do
    query = from a in Innerpeace.Db.Schemas.Authorization, select: a.number
    list_of_authorizations = Repo.all query
    result_generated = generate_random()
    case check_if_exists(list_of_authorizations, result_generated) do
      true  ->
        random_loa_number()
      false ->
        result_generated
    end
  end

  def check_if_exists(list, generated) do
    Enum.member?(list, generated)
  end

  def generate_random do
    random = 100_000_000..999_999_999 |> Enum.random() |> to_string()
  end
  # MemberLink End

  # ACU
  def acu_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :admission_datetime,
      :discharge_datetime,
      :internal_remarks,
      :status,
      :version,
      :member_id,
      :facility_id,
      :coverage_id,
      :created_by_id,
      :updated_by_id,
      :step,
      :room_id,
      :valid_until,
      :origin,
      :approved_by_id,
      :approved_datetime,
      :is_peme?
    ])
    |> validate_required([
      :member_id,
      :facility_id,
      :coverage_id,
      :created_by_id,
      :updated_by_id
    ])
  end
  # End ACU

  # PEME
  def peme_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :admission_datetime,
      :discharge_datetime,
      :internal_remarks,
      :status,
      :version,
      :member_id,
      :facility_id,
      :coverage_id,
      :created_by_id,
      :updated_by_id,
      :step,
      :room_id,
      :valid_until,
      :origin,
      :approved_by_id,
      :approved_datetime,
      :is_peme?
    ])
  end
  # END PEME

  def loa_number_changeset(struct) do
    struct
    |> cast(%{}, [])
    |> put_change(:number, random_loa_number())
  end

  def otp_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :otp,
      :otp_expiry
    ])
    |> validate_required([
      :otp,
      :otp_expiry
    ])
  end

  def status_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :status
    ])
    |> validate_required([
      :status
    ])
  end

  #for insert utilization
  def utilization_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :coverage_id,
      :member_id,
      :facility_id,
      :consultation_type,
      :chief_complaint,
      :chief_complaint_others,
      :internal_remarks,
      :assessed_amount,
      :total_amount,
      :status,
      :version,
      :step,
      :admission_datetime,
      :discharge_datetime,
      :availment_type,
      :created_by_id,
      :updated_by_id,
      :reason
    ])
    |> validate_required([
      :consultation_type,
      :admission_datetime,
      :coverage_id,
      :facility_id,
      :member_id
    ])
    |> put_change(:number, random_loa_number())
    |> put_change(:control_number, random_loa_number())
  end

  def changeset_create_api(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :admission_datetime,
      :consultation_type,
      :chief_complaint,
      :internal_remarks,
      :member_id,
      :facility_id,
      :coverage_id,
      :created_by_id,
      :updated_by_id,
      :step,
      :valid_until
    ])
    |> validate_required([
      :created_by_id,
      :step,
      :updated_by_id
    ])
  end

  def changeset_control_number(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :control_number
    ])
    |> validate_required([
      :control_number
    ])
  end

  def changeset_loa_number(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :number
    ])
    |> validate_required([
      :number
    ])
  end

  def changeset_status(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :status
    ])
    |> validate_required([
      :status
    ])
  end

  def approve_changeset_status(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :status,
      :approved_by_id,
      :approved_datetime,
      :origin
    ])
    |> validate_required([
      :status
    ])
    |> put_change(:number, random_loa_number())
    |> put_change(:control_number, random_loa_number())
  end

  def edit_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :edited_by_id,
      :updated_by_id
    ])
  end

  def copy_auth_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :coverage_id,
      :member_id,
      :facility_id,
      :consultation_type,
      :chief_complaint,
      :chief_complaint_others,
      :internal_remarks,
      :assessed_amount,
      :total_amount,
      :status,
      :version,
      :step,
      :admission_datetime,
      :discharge_datetime,
      :requested_datetime,
      :availment_type,
      :created_by_id,
      :updated_by_id,
      :reason,
      :internal_remarks,
      :availment_type,
      :transaction_no,
      :special_approval_id,
      :valid_until,
      :approved_by_id,
      :approved_datetime,
      :origin
    ])
    |> validate_required([
      :consultation_type,
      :admission_datetime,
      :coverage_id,
      :facility_id,
      :member_id
    ])
    |> put_change(:number, random_loa_number())
    |> put_change(:control_number, random_loa_number())
  end

  #for loa pos terminal
  def changeset_pos_terminal(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :loe_number,
      :coverage_id,
      :member_id,
      :facility_id,
      :step,
      :origin,
      :transaction_no,
      :swipe_datetime,
      :created_by_id,
      :status
    ])
  end

  #for loa pos terminal
  def peme_terminal(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :otp,
      :availment_date,
      :status
    ])
  end

  def claims_file_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :is_claimed?
    ])
  end

  def vendor_oplab_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :chief_complaint,
      :total_amount,
      :status,
      :admission_datetime,
      :discharge_datetime,
      :valid_until,
      :origin,
      :approved_datetime,
      :facility_id,
      :coverage_id,
      :version,
      :member_id,
      :step,
      :created_by_id,
      :updated_by_id,
      :approved_by_id,
      :requested_datetime,
      :transaction_no
    ])
    |> put_change(:number, random_loa_number())
    |> put_change(:control_number, random_loa_number())
  end

  def changeset_loe_no(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :loe_number
    ])
  end

  def changeset_acu_sched(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :member_id,
      :facility_id,
      :coverage_id,
      :step,
      :created_by_id,
      :origin,
      :approved_by_id,
      :approved_datetime,
      :updated_by_id,
      :otp,
      :version,
      :status,
      :valid_until,
      :transaction_no,
      :admission_datetime
    ])
    |> put_change(:number, random_loa_number())
  end

  def changeset_facial_image(struct, params \\ %{}) do
    struct
    |> cast(params, [:facial_image])
  end
end
