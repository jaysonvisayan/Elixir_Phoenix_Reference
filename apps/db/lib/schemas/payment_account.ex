defmodule Innerpeace.Db.Schemas.PaymentAccount do
  @moduledoc """
    Schema and changesets for PaymentAccount
  """
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [:account_tin]}
  schema "payment_accounts" do
    field :bank_account, :string
    field :mode_of_payment, :string
    field :account_tin, :string
    field :vat_status, :string
    field :p_sched_of_payment, :string
    field :d_sched_of_payment, :string
    field :previous_carrier, :string
    field :attached_point, :string
    field :revolving_fund, :string
    field :threshold, :string
    field :funding_arrangement, :string
    field :authority_debit, :boolean, default: false
    field :payee_name, :string
    field :bank_name, :string
    field :bank_branch, :string

    belongs_to :account_group, Innerpeace.Db.Schemas.AccountGroup
    has_many :account_logs, Innerpeace.Db.Schemas.AccountLog,
      on_delete: :delete_all
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:bank_account, :mode_of_payment])
    |> validate_required([:bank_account, :mode_of_payment])
  end

  def changeset_account(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :payee_name,
      :account_group_id,
      :account_tin,
      :vat_status,
      :mode_of_payment,
      :p_sched_of_payment,
      :d_sched_of_payment,
      :previous_carrier,
      :attached_point,
      :revolving_fund,
      :threshold,
      :funding_arrangement,
      :authority_debit
    ])
    # |> unique_constraint(
    #     :account_tin,
    #     name: :payment_accounts_account_tin_index,
    #     message: "Account TIN is already exist!")
    |> validate_required([
      :account_group_id,
      :account_tin,
      :vat_status,
    ])
    |> assoc_constraint(:account_group)

  end

  def changeset_account_v2(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :bank_account,
      :payee_name,
      :account_group_id,
      :account_tin,
      :vat_status,
      :mode_of_payment,
      :p_sched_of_payment,
      :d_sched_of_payment,
      :previous_carrier,
      :attached_point,
      :revolving_fund,
      :threshold,
      :funding_arrangement,
      :authority_debit,
      :bank_name,
      :bank_branch
    ])
  end
end
