defmodule Innerpeace.Db.Schemas.Facility do
  @moduledoc """
    Schema and changesets for facility
  """

  use Innerpeace.Db.Schema
  use Arc.Ecto.Schema

  @derive {Poison.Encoder, only: [
    :id,
    :region,
    :code,
    :name,
    :type,
    :latitude,
    :longitude,
    :type,
    :phone_no,
    :line_1,
    :line_2,
    :city,
    :province,
    :country,
    :postal_code,
    :facility_location_groups,
    :prescription_term
  ]}

  schema "facilities" do
    field :code, :string
    # Step 1 - General
    field :name, :string
    field :license_name, :string
    field :loa_condition, :boolean
    field :cutoff_time, Ecto.Time
    field :phic_accreditation_from, Ecto.Date
    field :phic_accreditation_to, Ecto.Date
    field :phic_accreditation_no, :string
    field :status, :string
    field :affiliation_date, Ecto.Date
    field :disaffiliation_date, Ecto.Date
    field :phone_no, :string
    field :email_address, :string
    field :website, :string
    field :logo, Innerpeace.ImageUploader.Type



    # Step 2 - Address
    field :line_1, :string
    field :line_2, :string
    field :city, :string
    field :province, :string
    field :region, :string
    field :country, :string
    field :postal_code, :string
    field :longitude, :string
    field :latitude, :string

    # Step 4 - Financial
    field :tin, :string
    field :prescription_term, :integer
    field :credit_term, :integer
    field :credit_limit, :integer
    field :no_of_beds, :string
    field :bond, :decimal
    field :payee_name, :string
    field :withholding_tax, :string
    field :bank_account_no, :string
    field :balance_biller, :boolean
    field :authority_to_credit, :boolean

    field :step, :integer

    field :vendor_code, :string

    #Relationships
    belongs_to :category, Innerpeace.Db.Schemas.Dropdown,
      foreign_key: :fcategory_id
    belongs_to :type, Innerpeace.Db.Schemas.Dropdown,
      foreign_key: :ftype_id
    belongs_to :vat_status, Innerpeace.Db.Schemas.Dropdown,
      foreign_key: :vat_status_id
    belongs_to :prescription_clause, Innerpeace.Db.Schemas.Dropdown,
      foreign_key: :prescription_clause_id
    belongs_to :payment_mode, Innerpeace.Db.Schemas.Dropdown,
      foreign_key: :payment_mode_id
    belongs_to :releasing_mode, Innerpeace.Db.Schemas.Dropdown,
      foreign_key: :releasing_mode_id
    belongs_to :created_by, Innerpeace.Db.Schemas.User,
      foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User,
      foreign_key: :updated_by_id

    has_many :product_facilities, Innerpeace.Db.Schemas.ProductFacility,
      on_delete: :delete_all
    has_many :facility_payor_procedures,
      Innerpeace.Db.Schemas.FacilityPayorProcedure, on_delete: :delete_all
    has_many :package_facility, Innerpeace.Db.Schemas.PackageFacility,
      on_delete: :delete_all
    has_many :facility_files, Innerpeace.Db.Schemas.FacilityFile,
      on_delete: :delete_all
    has_many :facility_room_rates, Innerpeace.Db.Schemas.FacilityRoomRate,
      on_delete: :nothing
    has_many :authorizations, Innerpeace.Db.Schemas.Authorization
    has_many :facility_payor_procedure_upload_files,
      Innerpeace.Db.Schemas.FacilityPayorProcedureUploadFile
    has_many :facility_ruvs, Innerpeace.Db.Schemas.FacilityRUV
    has_many :facility_service_fees, Innerpeace.Db.Schemas.FacilityServiceFee,
      on_delete: :delete_all
    has_many :product_coverage_facilities,
      Innerpeace.Db.Schemas.ProductCoverageFacility, on_delete: :delete_all
    has_many :practitioner_facilities,
      Innerpeace.Db.Schemas.PractitionerFacility, on_delete: :delete_all
    has_many :product_coverage_limit_threshold_facilities,
      Innerpeace.Db.Schemas.ProductCoverageLimitThresholdFacility,
      on_delete: :delete_all
    has_many :facility_location_groups,
      Innerpeace.Db.Schemas.FacilityLocationGroup,
      on_delete: :nothing

    has_many :users,
      Innerpeace.Db.Schemas.User,
      on_delete: :nothing

    many_to_many :practitioners, Innerpeace.Db.Schemas.Practitioner,
      join_through: "practitioner_facilities"

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :license_name,
      :ftype_id,
      :fcategory_id,
      :phic_accreditation_from,
      :phic_accreditation_to,
      :phic_accreditation_no,
      :status,
      :affiliation_date,
      :disaffiliation_date,
      :phone_no,
      :email_address,
      :website,
      :line_1,
      :line_2,
      :city,
      :province,
      :region,
      :country,
      :postal_code,
      :longitude,
      :latitude,
      :tin,
      :vat_status_id,
      :prescription_term,
      :prescription_clause_id,
      :credit_term,
      :credit_limit,
      :payment_mode_id,
      :releasing_mode_id,
      :no_of_beds,
      :bond,
      :step,
      :created_by_id,
      :updated_by_id
    ])
    |> validate_required([
      :updated_by_id,
      :step
    ])
    |> unique_constraint(
      :code,
      message: "Facility code already exists!"
    )
  end

  def step1_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :license_name,
      :ftype_id,
      :fcategory_id,
      :loa_condition,
      :cutoff_time,
      :phic_accreditation_from,
      :phic_accreditation_to,
      :phic_accreditation_no,
      :status,
      :affiliation_date,
      :disaffiliation_date,
      :phone_no,
      :email_address,
      :website,
      :line_1,
      :line_2,
      :city,
      :province,
      :region,
      :country,
      :postal_code,
      :longitude,
      :latitude,
      :tin,
      :vat_status_id,
      :prescription_term,
      :prescription_clause_id,
      :credit_term,
      :credit_limit,
      :payment_mode_id,
      :releasing_mode_id,
      :no_of_beds,
      :bond,
      :step,
      :created_by_id,
      :updated_by_id,
    ])
    |> validate_required([
      :code,
      :name,
      :ftype_id,
      :fcategory_id,
      :status,
      :step,
      :created_by_id,
      :updated_by_id
    ])
    |> cast_attachments(params, [:logo])
    |> validate_number(
      :phic_accreditation_no,
      message: "Must be a number"
    )
    |> validate_format(:email_address, ~r/@/)
    |> unique_constraint(
      :code,
      message: "Facility code already exists!"
    )
  end

  def step2_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :license_name,
      :ftype_id,
      :fcategory_id,
      :phic_accreditation_from,
      :phic_accreditation_to,
      :phic_accreditation_no,
      :status,
      :affiliation_date,
      :disaffiliation_date,
      :phone_no,
      :email_address,
      :website,
      :line_1,
      :line_2,
      :city,
      :province,
      :region,
      :country,
      :postal_code,
      :longitude,
      :latitude,
      :tin,
      :vat_status_id,
      :prescription_term,
      :prescription_clause_id,
      :credit_term,
      :credit_limit,
      :payment_mode_id,
      :releasing_mode_id,
      :no_of_beds,
      :bond,
      :step,
      :created_by_id,
      :updated_by_id
    ])
    |> validate_required(
      [
        :city,
        :province,
        :region,
        :country,
        :postal_code,
        :longitude,
        :latitude,
        :step,
        :updated_by_id
      ],
      message: "This is a required field"
    )
  end

  def step4_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :license_name,
      :ftype_id,
      :fcategory_id,
      :phic_accreditation_from,
      :phic_accreditation_to,
      :phic_accreditation_no,
      :status,
      :affiliation_date,
      :disaffiliation_date,
      :phone_no,
      :email_address,
      :website,
      :line_1,
      :line_2,
      :city,
      :province,
      :region,
      :country,
      :postal_code,
      :longitude,
      :latitude,
      :tin,
      :vat_status_id,
      :prescription_term,
      :prescription_clause_id,
      :credit_term,
      :credit_limit,
      :payment_mode_id,
      :releasing_mode_id,
      :no_of_beds,
      :bond,
      :step,
      :created_by_id,
      :updated_by_id,
      :payee_name,
      :withholding_tax,
      :bank_account_no,
      :balance_biller,
      :authority_to_credit
    ])
    |> validate_required([
      :tin,
      :vat_status_id,
      :prescription_term,
      :prescription_clause_id,
      :credit_term,
      :credit_limit,
      :payment_mode_id,
      :releasing_mode_id,
      :withholding_tax,
      :balance_biller,
      :step,
      :updated_by_id
    ])
  end

  def update_general_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :license_name,
      :ftype_id,
      :fcategory_id,
      :phic_accreditation_from,
      :phic_accreditation_to,
      :phic_accreditation_no,
      :status,
      :affiliation_date,
      :disaffiliation_date,
      :phone_no,
      :email_address,
      :website,
      :line_1,
      :line_2,
      :city,
      :province,
      :region,
      :country,
      :postal_code,
      :longitude,
      :latitude,
      :tin,
      :vat_status_id,
      :prescription_term,
      :prescription_clause_id,
      :credit_term,
      :credit_limit,
      :payment_mode_id,
      :releasing_mode_id,
      :no_of_beds,
      :bond,
      :step,
      :created_by_id,
      :updated_by_id,
    ])
    |> validate_required([
      :name,
      :license_name,
      :ftype_id,
      :fcategory_id,
      :phic_accreditation_from,
      :phic_accreditation_to,
      :phic_accreditation_no,
      :status,
      :affiliation_date,
      :disaffiliation_date,
      :updated_by_id
    ])
    |> cast_attachments(params, [:logo])
  end

  def update_address_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :license_name,
      :ftype_id,
      :fcategory_id,
      :phic_accreditation_from,
      :phic_accreditation_to,
      :phic_accreditation_no,
      :status,
      :affiliation_date,
      :disaffiliation_date,
      :phone_no,
      :email_address,
      :line_1,
      :line_2,
      :city,
      :province,
      :region,
      :country,
      :postal_code,
      :longitude,
      :latitude,
      :tin,
      :vat_status_id,
      :prescription_term,
      :prescription_clause_id,
      :credit_term,
      :credit_limit,
      :payment_mode_id,
      :releasing_mode_id,
      :no_of_beds,
      :bond,
      :step,
      :created_by_id,
      :updated_by_id
    ])
    |> validate_required([
      :line_1,
      :line_2,
      :city,
      :province,
      :region,
      :country,
      :postal_code,
      :longitude,
      :latitude,
      :updated_by_id
    ])
  end

  def update_financial_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :license_name,
      :ftype_id,
      :fcategory_id,
      :phic_accreditation_from,
      :phic_accreditation_to,
      :phic_accreditation_no,
      :status,
      :affiliation_date,
      :disaffiliation_date,
      :phone_no,
      :email_address,
      :line_1,
      :line_2,
      :city,
      :province,
      :region,
      :country,
      :postal_code,
      :longitude,
      :latitude,
      :tin,
      :vat_status_id,
      :prescription_term,
      :prescription_clause_id,
      :credit_term,
      :credit_limit,
      :payment_mode_id,
      :releasing_mode_id,
      :no_of_beds,
      :bond,
      :step,
      :created_by_id,
      :updated_by_id,
    ])
    |> validate_required([
      :tin,
      :updated_by_id
    ])
  end

  def changeset_facility_seed(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :license_name,
      :ftype_id,
      :fcategory_id,
      :phic_accreditation_from,
      :phic_accreditation_to,
      :phic_accreditation_no,
      :status,
      :affiliation_date,
      :disaffiliation_date,
      :phone_no,
      :email_address,
      :website,
      :line_1,
      :line_2,
      :city,
      :province,
      :region,
      :country,
      :postal_code,
      :longitude,
      :latitude,
      :tin,
      :vat_status_id,
      :prescription_term,
      :prescription_clause_id,
      :credit_term,
      :credit_limit,
      :payment_mode_id,
      :releasing_mode_id,
      :no_of_beds,
      :bond,
      :step,
      :created_by_id,
      :updated_by_id,
      :withholding_tax,
      :bank_account_no
    ])
    |> validate_required([
      :code,
      :name,
      :ftype_id,
      :fcategory_id,
      :status,
      :step,
      :created_by_id,
      :updated_by_id
    ])
    |> cast_attachments(params, [:logo])
    |> validate_number(
      :phic_accreditation_no,
      message: "Must be a number"
    )
    |> validate_format(:email_address, ~r/@/)
    |> unique_constraint(
      :code,
      message: "Facility code already exists!"
    )
  end

  def changeset_batch_upload(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :ftype_id,
      :license_name,
      :phic_accreditation_from,
      :phic_accreditation_to,
      :phic_accreditation_no,
      :status,
      :affiliation_date,
      :phone_no,
      :email_address,
      :website,
      :line_1,
      :line_2,
      :city,
      :province,
      :region,
      :country,
      :postal_code,
      :longitude,
      :latitude,
      :tin,
      :prescription_term,
      :credit_term,
      :credit_limit,
      :no_of_beds,
      :bond,
      :payee_name,
      :withholding_tax,
      :bank_account_no,
      :balance_biller,
      :authority_to_credit,
      :vat_status_id,
      :prescription_clause_id,
      :payment_mode_id,
      :releasing_mode_id,
      :fcategory_id
    ])
    |> validate_required([
        :code,
        :name,
        :ftype_id,
        :status,
        :city,
        :province,
        :region,
        :country,
        :postal_code,
        :longitude,
        :latitude,
        :tin,
        :prescription_term,
        :credit_term,
        :credit_limit,
        :withholding_tax,
        :balance_biller,
        :authority_to_credit,
        :vat_status_id,
        :prescription_clause_id,
        :payment_mode_id,
        :releasing_mode_id,
        :fcategory_id
      ])
  end
end
