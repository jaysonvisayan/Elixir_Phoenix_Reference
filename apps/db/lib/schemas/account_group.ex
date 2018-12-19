defmodule Innerpeace.Db.Schemas.AccountGroup do
  @moduledoc """
    Schema and changesets for AccountGroup
  """
  use Innerpeace.Db.Schema
  use Arc.Ecto.Schema

  @derive {Poison.Encoder, only: [
    :name,
    :code
  ]}

  schema "account_groups" do
    field :name, :string
    field :code, :string
    field :type, :string
    field :description, :string
    field :segment, :string
    field :security, :string, virtual: true
    field :phone_no, :string
    field :email, :string
    field :remarks, :string
    field :policy_no, :string
    field :photo, Innerpeace.ImageUploader.Type
    field :original_effective_date, Ecto.Date
    field :principal_enrollment_period, :integer
    field :dependent_enrollment_period, :integer
    field :pep_day_or_month, :string
    field :dep_day_or_month, :string

    field :replicated, :string

    # Approval
    field :mode_of_payment, :string
    field :payee_name, :string
    field :account_no, :string
    field :account_name, :string
    field :branch, :string
    field :is_check, :boolean, default: false

    belongs_to :industry, Innerpeace.Db.Schemas.Industry
    has_many :account_group_cluster, Innerpeace.Db.Schemas.AccountGroupCluster, on_delete: :delete_all
    has_many :account, Innerpeace.Db.Schemas.Account, on_delete: :delete_all
    has_many :account_group_contacts, Innerpeace.Db.Schemas.AccountGroupContact, on_delete: :delete_all
    has_many :account_group_address, Innerpeace.Db.Schemas.AccountGroupAddress, on_delete: :delete_all
    many_to_many :contacts, Innerpeace.Db.Schemas.Contact, join_through: "account_group_contacts"
    has_one :payment_account, Innerpeace.Db.Schemas.PaymentAccount, on_delete: :delete_all
    has_one :bank, Innerpeace.Db.Schemas.Bank, on_delete: :delete_all
    has_many :account_logs, Innerpeace.Db.Schemas.AccountLog, on_delete: :delete_all
    has_many :account_group_fulfillments, Innerpeace.Db.Schemas.AccountGroupFulfillment, on_delete: :delete_all
    has_many :members, Innerpeace.Db.Schemas.Member,
              foreign_key: :account_code, references: :code, on_delete: :delete_all
    has_many :practitioner_accounts, Innerpeace.Db.Schemas.PractitionerAccount, on_delete: :delete_all
    has_many :account_hierarchy_of_eligible_dependents,
              Innerpeace.Db.Schemas.AccountHierarchyOfEligibleDependent, on_delete: :delete_all
    has_many :account_group_coverage_funds, Innerpeace.Db.Schemas.AccountGroupCoverageFund, on_delete: :delete_all

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :code,
      :type,
      :description,
      :segment,
      :security,
      :phone_no,
      :email,
      :policy_no,
      :industry_id,
      :remarks,
      :original_effective_date
    ])
    |> unique_constraint(:code, name: :account_groups_code_index, message: "Account code is already exist!")
    |> validate_required([
      :name,
      :type,
      :segment,
      :industry_id,
      :original_effective_date
     ])
    |> validate_length(:name, min: 4, message: "Atleast 4 characters")
    |> validate_length(:code, min: 3, message: "Atleast 3 characters")
  end

  def changeset_photo(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:photo])
  end

  def changeset_financial(struct, params \\ %{}) do
    struct
    |> cast(params, [:mode_of_payment, :payee_name, :account_no, :account_name, :branch, :is_check])
  end

  def changeset_update_replicated(struct, params \\ %{}) do
    struct
    |> cast(params, [:replicated])
    |> validate_required([:replicated])
  end

  def enrollment_period_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :principal_enrollment_period,
      :dependent_enrollment_period,
      :pep_day_or_month,
      :dep_day_or_month
    ])
    |> validate_required([
      :principal_enrollment_period,
      :dependent_enrollment_period,
      :pep_day_or_month,
      :dep_day_or_month
    ])
  end

  def changeset_sap(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :code,
      :segment,
      :type,
      :industry_id,
      :original_effective_date,
      :phone_no,
      :email,
      :payee_name,
      :account_no,
      :account_name,
      :branch,
      :mode_of_payment,
    ])
  end

end
