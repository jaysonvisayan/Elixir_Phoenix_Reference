defmodule Innerpeace.Db.Schemas.Member do
  @moduledoc """
  """

  use Innerpeace.Db.Schema
  use Arc.Ecto.Schema

  alias Innerpeace.Db.Utilities.CardNoGenerator

  @derive {Poison.Encoder, only: [
    :account_code,
    :employee_no,
    :email,
    :mobile
  ]}

  schema "members" do
    field :photo, Innerpeace.ImageUploader.Type
    field :type, :string
    field :effectivity_date, Ecto.Date
    field :expiry_date, Ecto.Date
    field :first_name, :string
    field :middle_name, :string
    field :last_name, :string
    field :suffix, :string
    field :gender, :string
    field :civil_status, :string
    field :birthdate, Ecto.Date
    field :employee_no, :string
    field :date_hired, Ecto.Date
    field :is_regular, :boolean, default: false
    field :regularization_date, Ecto.Date
    field :tin, :string
    field :philhealth, :string
    field :for_card_issuance, :boolean, default: false
    field :email, :string
    field :email2, :string
    field :mobile, :string
    field :mobile2, :string
    field :telephone, :string
    field :fax, :string
    field :postal, :string
    field :unit_no, :string
    field :building_name, :string
    field :street_name, :string
    field :city, :string
    field :province, :string
    field :region, :string
    field :country, :string
    field :status, :string
    field :card_no, :string
    field :relationship, :string
    field :policy_no, :string
    field :step, :integer
    field :cancel_date, Ecto.Date
    field :cancel_reason, :string
    field :cancel_remarks, :string
    field :suspend_date, Ecto.Date
    field :suspend_reason, :string
    field :suspend_remarks, :string
    field :reactivate_date, Ecto.Date
    field :reactivate_reason, :string
    field :reactivate_remarks, :string
    field :salutation, :string
    field :blood_type, :string
    field :allergies, :string
    field :medication, :string
    field :philhealth_type, :string
    field :enrollment_date, Ecto.Date
    field :card_expiry_date, Ecto.Date
    field :vip, :boolean, default: false
    field :senior, :boolean, default: false
    field :senior_id, :string
    field :senior_photo, Innerpeace.ImageUploader.Type
    field :pwd, :boolean, default: false
    field :pwd_id, :string
    field :pwd_photo, Innerpeace.ImageUploader.Type
    field :evoucher_number, :string
    field :evoucher_qr_code, :string
    field :secondary_id, Innerpeace.FileUploader.Type
    field :attempts, :integer, default: 0
    field :attempt_expiry, Ecto.DateTime
    field :integration_id, :string
    field :last_attempted, Ecto.DateTime
    field :primary_id, Innerpeace.FileUploader.Type
    field :temporary_member, :boolean, default: false

    # Change of Product Effective Date
    field :cop_effective_date, Ecto.Date

    ## updated contact
    field :mcc, :string  # mobile_country_code
    field :mcc2, :string # mobile2_country_code
    field :tcc, :string  # tel_country_code
    field :tac, :string  # tel_area_code
    field :tlc, :string  # tel_local_code
    field :fcc, :string  # fax_country_code
    field :fac, :string  # fax_area_code
    field :flc, :string  # fax_local_code

    # fields pending for approval
    #field :card_no, :string
    #field :status, :string
    #field :member_id, :string

    # has_one :member, Innerpeace.Member, on_delete: :delete_all
    #    has_many :user_roles, Innerpeace.Db.Schemas.UserRole, on_delete: :delete_all
    #    many_to_many :roles, Innerpeace.Db.Schemas.Role, join_through: "user_roles"
    #    #has_many :agents, Innerpeace.Db.Schemas.Agent, on_delete: :delete_all
    has_many :products, Innerpeace.Db.Schemas.MemberProduct, on_delete: :delete_all
    has_many :dependents, Innerpeace.Db.Schemas.Member, foreign_key: :principal_id
    belongs_to :principal, Innerpeace.Db.Schemas.Member, foreign_key: :principal_id
    belongs_to :account_group,
      Innerpeace.Db.Schemas.AccountGroup,
      foreign_key: :account_code,
      references: :code,
      type: :string
    belongs_to :prinicipal_member_product, Innerpeace.Db.Schemas.MemberProduct, foreign_key: :principal_product_id
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id

    has_many :member_comments, Innerpeace.Db.Schemas.MemberComment

    has_many :authorizations, Innerpeace.Db.Schemas.Authorization
    has_many :member_contacts, Innerpeace.Db.Schemas.MemberContact
    has_many :emergency_hospital, Innerpeace.Db.Schemas.EmergencyHospital
    has_many :skipped_dependents, Innerpeace.Db.Schemas.MemberSkippingHierarchy
    has_one :kyc_bank, Innerpeace.Db.Schemas.KycBank
    has_one :emergency_contact, Innerpeace.Db.Schemas.EmergencyContact
    has_many :member_logs, Innerpeace.Db.Schemas.MemberLog, on_delete: :delete_all
    has_many :member_documents, Innerpeace.Db.Schemas.MemberDocument, on_delete: :delete_all

    has_one :user, Innerpeace.Db.Schemas.User

    has_many :files, Innerpeace.Db.Schemas.File
    has_one :peme, Innerpeace.Db.Schemas.Peme, on_delete: :nothing
    has_one :peme_members, Innerpeace.Db.Schemas.PemeMember
    has_many :acu_schedule_members, Innerpeace.Db.Schemas.AcuScheduleMember

    has_one :member_upload_log, Innerpeace.Db.Schemas.MemberUploadLog
    timestamps()
  end

  def changeset_general(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :card_no,
      :account_code,
      :type,
      :principal_id,
      :effectivity_date,
      :expiry_date,
      :first_name,
      :middle_name,
      :last_name,
      :suffix,
      :gender,
      :civil_status,
      :birthdate,
      :employee_no,
      :date_hired,
      :is_regular,
      :regularization_date,
      :tin,
      :philhealth,
      :for_card_issuance,
      :relationship,
      :created_by_id,
      :updated_by_id,
      :step,
      :philhealth_type,
      :status,
      :vip,
      :senior,
      :senior_id,
      :pwd,
      :pwd_id,
      :principal_product_id
    ])
    |> validate_required([
      :account_code,
      :type,
      :effectivity_date,
      :expiry_date,
      :first_name,
      :last_name,
      :gender,
      :civil_status,
      :birthdate,
      :for_card_issuance,
      :vip,
    ], message: "is a required field!")
    |> unique_constraint(:employee_no, name: :members_account_code_employee_no_index, message: "Employee number is already used within the selected account!")
  end


  def changeset_general_save_as_draft(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :card_no,
      :account_code,
      :type,
      :principal_id,
      :effectivity_date,
      :expiry_date,
      :first_name,
      :middle_name,
      :last_name,
      :suffix,
      :gender,
      :civil_status,
      :birthdate,
      :employee_no,
      :date_hired,
      :is_regular,
      :regularization_date,
      :tin,
      :philhealth,
      :for_card_issuance,
      :relationship,
      :created_by_id,
      :updated_by_id,
      :step,
      :philhealth_type,
      :status,
      :vip,
      :senior,
      :senior_id,
      :pwd,
      :pwd_id,
      :principal_product_id
    ])
    |> validate_required([
      :account_code,
      :first_name,
      :last_name,
    ], message: "is a required field!")
    |> unique_constraint(:employee_no, name: :members_account_code_employee_no_index, message: "Employee number is already used within the selected account!")
  end

  def changeset_card(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :card_no
    ])
    |> assign_card_no(CardNoGenerator.generate_card_number(nil))
  end

  def changeset_enroll(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :step,
      :updated_by_id,
      :enrollment_date,
      :card_expiry_date
    ])
    |> validate_required([
      :step,
      :updated_by_id,
      :enrollment_date,
      :card_expiry_date
    ])
  end

  def changeset_photo(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:photo])
  end

  def changeset_pwd_photo(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:pwd_photo])
  end

  def changeset_senior_photo(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:senior_photo])
  end

  def changeset_contact(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :email,
      :email2,
      ## new updates for member contact
      :mcc,
      :mcc2,
      :tcc,
      :tac,
      :tlc,
      :fcc,
      :fac,
      :flc,
      :fax,
      :telephone,
      :mobile,
      :mobile2,
      #####################
      :postal,
      :unit_no,
      :building_name,
      :street_name,
      :city,
      :province,
      :region,
      :country,
      :updated_by_id,
      :step,
      :status
    ])
    |> unmask_mobile(:mobile)
    |> unmask_mobile(:mobile2)

  end

  defp unmask_mobile(changeset, key) do
    with true <- Map.has_key?(changeset.changes, key),
         false <- is_nil(changeset.changes[key])
    do
      number =
        changeset
        |> get_change(key)
        |> String.replace("-", "")
      changeset
      |> put_change(key, number)
    else
      _ ->
        changeset
    end
  end

  def changeset_step(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :step,
      :updated_by_id
    ])
    |> validate_required([
      :step,
      :updated_by_id
    ])
  end

  def changeset_api(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :card_no,
      :account_code,
      :type,
      :principal_id,
      :effectivity_date,
      :expiry_date,
      :first_name,
      :middle_name,
      :last_name,
      :suffix,
      :gender,
      :civil_status,
      :birthdate,
      :employee_no,
      :date_hired,
      :is_regular,
      :regularization_date,
      :tin,
      :philhealth,
      :philhealth_type,
      :for_card_issuance,
      :relationship,
      :email,
      :email2,
      :mobile,
      :mobile2,
      :telephone,
      :fax,
      :postal,
      :unit_no,
      :building_name,
      :street_name,
      :city,
      :province,
      :region,
      :country,
      :created_by_id,
      :updated_by_id,
      :policy_no,
      :step,
      :enrollment_date,
      :status,
      :integration_id
    ])
    |> unique_constraint(:employee_no, name: :members_account_code_employee_no_index, message: "already exists within the account")
  end

  def changeset_suspend(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :suspend_date,
      :suspend_reason,
      :suspend_remarks
    ])
  end

  def changeset_cancel(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :cancel_date,
      :cancel_reason,
      :cancel_remarks
    ])
  end

  def changeset_reactivate(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :reactivate_date,
      :reactivate_reason,
      :reactivate_remarks
    ])
  end

  def changeset_movement(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :status,
      :effectivity_date,
      :expiry_date
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

  def changeset_status_cast(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :status
    ])
  end
  #Start MemberLink
  def changeset_memberlink_profile(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :first_name,
      :middle_name,
      :last_name,
      :gender,
      :birthdate,
      :account_code,
      :created_by_id,
      :updated_by_id,
      :card_no,
      :step
    ])
    |> validate_required([
      :first_name,
      :last_name,
      :gender,
      :birthdate
    ], message: "is a required field!")
  end

  def changeset_memberlink_dependent(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :salutation,
      :first_name,
      :middle_name,
      :last_name,
      :gender,
      :birthdate,
      :suffix,
      :relationship,
      :account_code,
      :created_by_id,
      :updated_by_id,
      :card_no, :step
    ])
    |> validate_required([
      :first_name,
      :last_name,
      :gender,
      :birthdate,
      :relationship
    ], message: "is a required field!")
  end

  def changeset_memberlink_info(struct, params \\ %{}) do
    struct
    |> cast(params, [:blood_type, :allergies, :medication])
  end

  def al_peme_changeset_general(struct, params \\ %{}) do
    # AccountLink PEME Single Changeset general

    struct
    |> cast(params, [
      :first_name,
      :middle_name,
      :last_name,
      :suffix,
      :birthdate,
      :civil_status,
      :gender,
      :effectivity_date,
      :philhealth,
      :expiry_date,
      :tin,
      :status,
      :card_no,
      :created_by_id,
      :updated_by_id,
      :step
    ])
    |> validate_required([
      :first_name,
      :middle_name,
      :last_name,
      :birthdate,
      :civil_status,
      :gender,
      :effectivity_date,
      :expiry_date,
      :step
    ], message: "is a required field!")
  end

  def al_peme_changeset_contact(struct, params \\ %{}) do
    # AccountLink PEME Single Changeset step

    struct
    |> cast(params, [
      :email,
      :email2,
      :mobile,
      :mobile2,
      :telephone,
      :fax,
      :postal,
      :unit_no,
      :building_name,
      :street_name,
      :city,
      :province,
      :region,
      :country,
      :created_by_id,
      :updated_by_id,
      :step
    ])
    |> validate_required([
      :email,
      :mobile,
      :step
    ], message: "is a required field!")
  end

  def al_peme_changeset_step(struct, params \\ %{}) do
    # AccountLink PEME Single Changeset step

    struct
    |> cast(params, [:step])
    |> validate_required([:step])
  end
  #End MemberLink

  defp assign_card_no(changeset), do: changeset
  defp assign_card_no(changeset, card_no) do
    case card_no do
      {:error, "Payor card bin not registered"} ->
        changeset
        |> add_error(:card_no, "Payor card bin not registered", additional: "info")
      {:error, "Invalid card bin length"} ->
        changeset
        |> add_error(:card_no, "Invalid card bin length", additional: "info")
      {:error, "Invalid card number base length"} ->
        changeset
        |> add_error(:card_no, "Invalid card number base length", additional: "info")
      _ ->
        case Repo.get_by(__MODULE__, card_no: card_no) do
          nil ->
            changeset
            |> put_change(:card_no, card_no)
          _ ->
            assign_card_no(changeset, CardNoGenerator.generate_card_number(nil))
        end
    end
  end

  def changeset_evoucher(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :evoucher_number,
      :evoucher_qr_code
    ])
    |> validate_required([
      :evoucher_number,
      :evoucher_qr_code
    ])
  end

  def changeset_update_evoucher(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :first_name,
      :middle_name,
      :last_name,
      :suffix,
      :birthdate,
      :civil_status,
      :gender,
      :mobile,
      :email,
      :account_code,
      :status,
      :step,
      :created_by_id,
      :updated_by_id,
      :relationship,
      :type,
      :effectivity_date,
      :expiry_date,
      :temporary_member
    ])
    |> validate_required([
      :first_name,
      :last_name,
      :birthdate,
      :gender,
      :mobile,
      :civil_status
    ])
  end

  def changeset_api_existing(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :card_no,
      :account_code,
      :type,
      :principal_id,
      :effectivity_date,
      :expiry_date,
      :first_name,
      :middle_name,
      :last_name,
      :suffix,
      :gender,
      :civil_status,
      :birthdate,
      :employee_no,
      :date_hired,
      :is_regular,
      :regularization_date,
      :tin,
      :philhealth,
      :philhealth_type,
      :for_card_issuance,
      :relationship,
      :email,
      :email2,
      :mobile,
      :mobile2,
      :telephone,
      :fax,
      :postal,
      :unit_no,
      :building_name,
      :street_name,
      :city,
      :province,
      :region,
      :country,
      :created_by_id,
      :updated_by_id,
      :policy_no,
      :step,
      :enrollment_date,
      :status,
      :integration_id
    ])
    |> unique_constraint(:employee_no, name: :members_account_code_employee_no_index, message: "already exists within the account")

  end

  def changeset_for_nil(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :senior,
    ])
  end

  def changeset_peme_member(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :first_name,
      :middle_name,
      :last_name,
      :birthdate,
      :civil_status,
      :gender,
      :step,
      :status,
      :account_code
    ])
  end

  def update_cop_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :cop_effective_date
    ])
    |> validate_required([:cop_effective_date])
  end

  def changeset_peme_evoucher(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:primary_id])
    |> cast_attachments(params, [:secondary_id])
    |> cast(params, [
      :first_name,
      :middle_name,
      :last_name,
      :birthdate,
      :civil_status,
      :gender,
      :birthdate,
      :mobile,
      :email,
      :status,
      :account_code,
      :suffix,
      :step,
      :effectivity_date,
      :expiry_date,
      :created_by_id,
      :updated_by_id,
      :type,
      :temporary_member
    ])
  end

  def changeset_update_peme_member_payorlink_one(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :integration_id,
      :card_no,
      :policy_no,
      :status,
      :step
    ])
  end

  def changeset_batch_card_no(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :card_no
    ])
  end

  def changeset_primary_id(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:primary_id])
  end

  def changeset_secondary_id(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:secondary_id])
  end
end
