defmodule Innerpeace.Db.Schemas.AccountLog do
  use Innerpeace.Db.Schema

  schema "account_logs" do
    belongs_to :account_group, Innerpeace.Db.Schemas.AccountGroup
    belongs_to :bank, Innerpeace.Db.Schemas.Bank
    belongs_to :account_group_address, Innerpeace.Db.Schemas.AccountGroupAddress
    belongs_to :contact, Innerpeace.Db.Schemas.Contact
    belongs_to :payment_account, Innerpeace.Db.Schemas.PaymentAccount
    belongs_to :account, Innerpeace.Db.Schemas.Account
    belongs_to :user, Innerpeace.Db.Schemas.User
    field :message, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :contact_id,
      :account_group_id,
      :user_id,
      :message
    ])
    |> validate_required([
      :user_id,
      :message
    ])
  end

end