defmodule Innerpeace.Db.Schemas.Account do
  @moduledoc """
    Schema and changesets for Account
  """
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :start_date,
    :end_date,
    :status,
    :account_group
  ]}

  schema "accounts" do
    field :start_date, Ecto.Date
    field :end_date, Ecto.Date
    field :status, :string
    field :created_by, :binary_id
    field :updated_by, :binary_id
    field :step, :integer
    field :major_version, :integer
    field :minor_version, :integer
    field :build_version, :integer
    field :cancel_date, Ecto.Date
    field :cancel_reason, :string
    field :cancel_remarks, :string
    field :suspend_date, Ecto.Date
    field :suspend_reason, :string
    field :suspend_remarks, :string
    field :reactivate_date, Ecto.Date
    field :reactivate_remarks, :string
    field :extend_remarks, :string

    belongs_to :account_group, Innerpeace.Db.Schemas.AccountGroup
    has_many :account_products, Innerpeace.Db.Schemas.AccountProduct, on_delete: :delete_all
    many_to_many :products, Innerpeace.Db.Schemas.Product, join_through: "account_products"
    has_many :account_comment, Innerpeace.Db.Schemas.AccountComment, on_delete: :delete_all
    has_one :payment_account, Innerpeace.Db.Schemas.PaymentAccount, on_delete: :delete_all
    has_many :account_logs, Innerpeace.Db.Schemas.AccountLog, on_delete: :delete_all
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :start_date,
      :end_date,
      :created_by,
      :updated_by,
      :account_group_id,
      :major_version,
      :minor_version,
      :build_version,
      :status,
      :step
    ])
    |> validate_required([
      :start_date,
      :end_date,
      :account_group_id,
      :updated_by,
      :step
    ])
  end

  def changeset_step(struct, params \\ %{}) do
    struct
    |> cast(params, [:step, :updated_by, :status])
  end

  def changeset_version(struct, params \\ %{}) do
    struct
    |> cast(params, [:major_version, :minor_version, :build_version])
  end

  def changeset_account(struct, params \\ %{}) do
    struct
    |> cast(params, [:start_date, :end_date, :status, :cancel_remarks, :cancel_reason, :cancel_date])
  end

  def changeset_suspend_account(struct, params \\ %{}) do
    struct
    |> cast(params, [:status, :suspend_date, :suspend_remarks, :suspend_reason])
    |> validate_required([:status, :suspend_date, :suspend_reason])
  end

  def changeset_account_expiry(struct, params \\ %{}) do
    struct
    |> cast(params, [:end_date])
    |> validate_required([:end_date])
  end

  def changeset_cancel_account(struct, params \\ %{}) do
    struct
    |> cast(params, [:status, :cancel_reason, :cancel_remarks, :cancel_date])
    |> validate_required([:status, :cancel_reason, :cancel_date])
  end

  def changeset_cancel_account_cluster(struct, params \\ %{}) do
    struct
    |> cast(params, [:status, :cancel_date, :cancel_reason, :cancel_remarks])
    |> validate_required([:status, :cancel_date, :cancel_reason])
  end

  def changeset_extend_account(struct, params \\ %{}) do
    struct
    |> cast(params, [:end_date])
    |> validate_required([:end_date])
  end

  def changeset_renew(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :created_by,
      :updated_by,
      :account_group_id,
      :major_version,
      :minor_version,
      :build_version,
      :status,
      :step
    ])
    |> validate_required([
      :created_by,
      :updated_by,
      :account_group_id,
      :major_version,
      :minor_version,
      :build_version,
      :status,
      :step
    ])
  end

  def changeset_api_renew(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :created_by,
      :updated_by,
      :account_group_id,
      :major_version,
      :minor_version,
      :build_version,
      :status,
      :start_date,
      :end_date,
      :step
    ])
    |> validate_required([
      :created_by,
      :updated_by,
      :account_group_id,
      :major_version,
      :minor_version,
      :build_version,
      :status,
      :start_date,
      :end_date,
      :step
    ])
  end

  def changeset_renew_cluster(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :created_by,
      :updated_by,
      :start_date,
      :end_date,
      :account_group_id,
      :major_version,
      :minor_version,
      :build_version,
      :status,
      :step
    ])
    |> validate_required([
      :created_by,
      :updated_by,
      :start_date,
      :end_date,
      :account_group_id,
      :major_version,
      :minor_version,
      :build_version,
      :status,
      :step
    ])
  end

  def changeset_status(struct, params \\ %{}) do
    struct
    |> cast(params, [:status])
    |> validate_required([:status])
  end

  def changeset_reactivate_account(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :status,
      :reactivate_date,
      :reactivate_remarks
    ])
    |> validate_required([
      :status,
      :reactivate_date
    ])
  end

def changeset_renew_sap_api(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :created_by,
      :updated_by,
      :account_group_id,
      :major_version,
      :minor_version,
      :build_version,
      :status,
      :step,
      :start_date,
      :end_date
    ])
    |> validate_required([
      :created_by,
      :updated_by,
      :account_group_id,
      :major_version,
      :minor_version,
      :build_version,
      :status,
      :step,
      :start_date,
      :end_date
    ])
  end

  def changeset_cancel_sap_api(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :created_by,
      :updated_by,
      :account_group_id,
      :status,
      :start_date,
      :end_date,
      :cancel_date,
      :cancel_reason,
      :cancel_remarks
    ])
    |> validate_required([
      :created_by,
      :updated_by,
      :cancel_date,
      :account_group_id,
      :step,
      :start_date,
      :end_date,
      :cancel_reason,
    ])
  end

  def changeset_reactivate_sap_api(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :created_by,
      :updated_by,
      :account_group_id,
      :status,
      :start_date,
      :end_date,
      :reactivate_date,
      :reactivate_remarks
    ])
    |> validate_required([
      :created_by,
      :updated_by,
      :reactivate_date,
      :account_group_id,
      :start_date,
      :end_date,
    ])
  end

  def changeset_suspend_sap_api(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :created_by,
      :updated_by,
      :account_group_id,
      :status,
      :start_date,
      :end_date,
      :suspend_date,
      :suspend_reason,
      :suspend_remarks
    ])
    |> validate_required([
      :created_by,
      :updated_by,
      :suspend_date,
      :account_group_id,
      :step,
      :start_date,
      :end_date,
      :suspend_reason
    ])
  end

  def changeset_extend_sap_api(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :created_by,
      :updated_by,
      :account_group_id,
      :extend_remarks,
      :status,
      :start_date,
      :end_date
    ])
    |> validate_required([
      :created_by,
      :updated_by,
      :account_group_id,
      :step,
      :start_date,
      :end_date
    ])
  end

end
