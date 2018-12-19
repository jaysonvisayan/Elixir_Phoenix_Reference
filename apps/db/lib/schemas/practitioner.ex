defmodule Innerpeace.Db.Schemas.Practitioner do
  use Innerpeace.Db.Schema
  use Arc.Ecto.Schema

  @moduledoc """
  Practitioner schemas
  """

  @derive {Poison.Encoder, only: [
    :code,
    :first_name,
    :middle_name,
    :last_name,
    :status,
    :id,
    :suffix,
    :practitioner_specializations
  ]}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @timestamps_opts [usec: false]
  schema "practitioners" do
    field :first_name, :string
    field :middle_name, :string
    field :last_name, :string
    field :birth_date, Ecto.Date
    field :effectivity_from, Ecto.Date
    field :effectivity_to, Ecto.Date
    field :suffix, :string
    field :gender, :string
    field :affiliated, :string
    field :prc_no, :string
    field :type, {:array, :string}
    field :step, :integer
    field :code, :string
    field :status, :string
    field :photo, Innerpeace.ImageUploader.Type
    field :specialization_ids, {:array, :string}, virtual: true
    field :sub_specialization_ids, {:array, :string}, virtual: true
    field :exclusive, {:array, :string}
    field :vat_status, :string
    field :prescription_period, :string
    field :tin, :string
    field :withholding_tax, :string
    field :payment_type, :string
    field :xp_card_no, :string
    field :payee_name, :string
    field :account_no, :string
    field :vendor_code, :string
    field :phic_accredited, :string
    field :phic_date, Ecto.Date


    timestamps()

    has_many :practitioner_specializations, Innerpeace.Db.Schemas.PractitionerSpecialization, on_delete: :delete_all
    many_to_many :specializations, Innerpeace.Db.Schemas.Specialization, join_through: "practitioner_specializations"
    has_one :practitioner_contact, Innerpeace.Db.Schemas.PractitionerContact, on_delete: :delete_all
    belongs_to :bank, Innerpeace.Db.Schemas.Bank

    belongs_to :dropdown_vat_status, Innerpeace.Db.Schemas.Dropdown, foreign_key: :vat_status_id

    has_many :practitioner_accounts, Innerpeace.Db.Schemas.PractitionerAccount, on_delete: :delete_all
    many_to_many :accounts, Innerpeace.Db.Schemas.Account, join_through: "practitioner_accounts"
    has_many :logs, Innerpeace.Db.Schemas.PractitionerLog, on_delete: :delete_all

    has_many :practitioner_facilities, Innerpeace.Db.Schemas.PractitionerFacility, on_delete: :delete_all
    many_to_many :facilities, Innerpeace.Db.Schemas.Facility, join_through: "practitioner_facilities"

    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :first_name,
      :middle_name,
      :last_name,
      :birth_date,
      :effectivity_from,
      :effectivity_to,
      :suffix,
      :gender,
      :affiliated,
      :prc_no,
      :type,
      :step,
      :code,
      :status,
      :specialization_ids,
      :sub_specialization_ids,
      :created_by_id,
      :updated_by_id,
      :phic_accredited,
      :phic_date
    ])
    |> validate_required([
      :first_name,
      :last_name,
      :birth_date,
      :prc_no,
      :specialization_ids,
      :phic_accredited
    ])
    |> put_change(:code, random_pcode())
  end

  def changeset_api_step1(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :first_name,
      :middle_name,
      :last_name,
      :birth_date,
      :effectivity_from,
      :effectivity_to,
      :suffix,
      :gender,
      :affiliated,
      :prc_no,
      :step,
      :code,
      :status,
      :specialization_ids,
      :sub_specialization_ids,
      :created_by_id,
      :updated_by_id
    ])
    |> validate_required([
      :first_name,
      :last_name,
      :birth_date,
      :prc_no,
      :specialization_ids
    ])
  end

  def changeset_general_edit(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :first_name,
      :middle_name,
      :last_name,
      :birth_date,
      :effectivity_from,
      :effectivity_to,
      :suffix,
      :gender,
      :affiliated,
      :prc_no,
      :type,
      :step,
      :code,
      :status,
      :specialization_ids,
      :sub_specialization_ids,
      :created_by_id,
      :updated_by_id,
      :phic_accredited,
      :phic_date
    ])
    |> validate_required([
      :first_name,
      :last_name,
      :birth_date,
      :prc_no,
      :phic_accredited,
      :specialization_ids
    ])
  end

  def changeset_photo(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:photo])
  end

  def changeset_financial(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :exclusive,
      # :vat_status,
      :prescription_period,
      :tin,
      :withholding_tax,
      :payment_type,
      :xp_card_no,
      :payee_name,
      :updated_by_id,
      :account_no,
      :bank_id,
      :vat_status_id
    ])
    |> validate_required([
      :exclusive,
      :vat_status_id,
      :tin,
    ])
  end

  def changeset_step(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :step,
      :updated_by_id
    ])
  end

  def changeset_status(struct, params \\ %{}) do
    struct
    |> cast(params, [:status])
  end

  def random_pcode() do
    query = from p in Innerpeace.Db.Schemas.Practitioner, select: p.code
    list_of_practitioners = Repo.all query
    result_generated = generate_random()
    case check_if_exists(list_of_practitioners, result_generated) do
      true  ->
        random_pcode()
      false ->
        result_generated
    end
  end

  def check_if_exists(list, generated) do
    Enum.member?(list, generated)
  end

  def generate_random() do
    prefix = "PRA-"
    random = Enum.random(100_000..999_999)
    concatresult = "#{prefix}#{random}"
  end

  def changeset_practitioner_seed(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :first_name,
      :middle_name,
      :last_name,
      :gender,
      :suffix,
      :affiliated,
      :prc_no,
      :status,
      :exclusive,
      :vat_status,
      :tin,
      :payment_type,
      :bank_id,
      :payee_name,
      :account_no,
      :created_by_id,
      :updated_by_id,
      :step,
      :birth_date,
      :effectivity_from,
      :effectivity_to,
      :status
    ])
    |> put_change(:code, random_pcode())
  end

end
