defmodule Innerpeace.Db.Schemas.Contact do
  @moduledoc false

  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :last_name,
    :first_name,
    :department,
    :designation,
    :phones,
    :fax,
    :email,
    :type,
    :ctc,
    :ctc_date_issued,
    :ctc_place_issued,
    :passport_no,
    :passport_date_issued,
    :passport_place_issued,
    :emails
  ]}

  schema "contacts" do
    field :first_name, :string
    field :last_name, :string
    field :designation, :string
    field :type, :string
    field :email, :string
    field :ctc, :string
    field :ctc_date_issued, Ecto.Date
    field :ctc_place_issued, :string
    field :passport_no, :string
    field :passport_date_issued, Ecto.Date
    field :passport_place_issued, :string
    field :department, :string
    field :relationship, :string
    field :middle_name, :string
    field :suffix, :string

    many_to_many :account_groups, Innerpeace.Db.Schemas.AccountGroup, join_through: "account_group_contacts"
    many_to_many :payors, Innerpeace.Db.Schemas.Payor, join_through: "payor_contacts"
    many_to_many :facilities, Innerpeace.Db.Schemas.Facility, join_through: "facility_contacts"
    has_many :account_group_contacts, Innerpeace.Db.Schemas.AccountGroupContact
    has_many :phones, Innerpeace.Db.Schemas.Phone, on_delete: :delete_all
    has_many :fax, Innerpeace.Db.Schemas.Fax, on_delete: :delete_all
    has_many :addresses, Innerpeace.Db.Schemas.Address
    has_many :emails, Innerpeace.Db.Schemas.Email, on_delete: :delete_all
    has_one :practitioner_contact, Innerpeace.Db.Schemas.PractitionerContact
    has_many :facility_contacts, Innerpeace.Db.Schemas.FacilityContact
    has_many :practitioner_account_contacts, Innerpeace.Db.Schemas.PractitionerAccountContact
    has_many :practitioner_facility_contacts, Innerpeace.Db.Schemas.PractitionerFacilityContact
    has_many :account_logs, Innerpeace.Db.Schemas.AccountLog, on_delete: :delete_all
    has_many :member_contacts, Innerpeace.Db.Schemas.MemberContact
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :first_name,
      :last_name,
      :designation,
      :type,
      :email,
      :ctc,
      :ctc_date_issued,
      :ctc_place_issued,
      :passport_no,
      :passport_date_issued,
      :passport_place_issued,
      :department
    ])
    |> validate_required([
      :last_name,
      :type,
    ])
    #  |> validate_length(:first_name, min: 3, max: 30, message: "Minimum of 3 and Maximum of 30 characters")
    #|> validate_length(:last_name, min: 2, max: 30, message: "Minimum of 2 and Maximum of 30 characters")
    #|> validate_length(:designation, min: 5, max:  30, message: "Minimum of 5 and Maximum of 30 characters")
  end

  def changeset_practitioner(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :last_name,
      :first_name,
      :department,
      :designation
    ])
  end

  def facility_contact_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :designation,
      :department,
      :last_name,
      :first_name,
      :email,
      :suffix
    ])
    |> validate_required([
      :last_name,
      :first_name,
      :email
    ])
  end

  def pfcontact_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :last_name,
      :first_name,
      :department,
      :designation
    ])
  end

  def member_emergency_contact_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :last_name,
      :first_name,
      :middle_name,
      :relationship
    ])
    |> validate_required([
      :last_name,
      :first_name,
      :relationship
    ])
  end
end
