defmodule Innerpeace.Db.Schemas.AccountGroupFulfillment do
  use Innerpeace.Db.Schema

  schema "account_group_fulfillments" do
    belongs_to :account_group, Innerpeace.Db.Schemas.AccountGroup
    belongs_to :fulfillment, Innerpeace.Db.Schemas.FulfillmentCard
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:account_group_id, :fulfillment_id])
    |> validate_required([:account_group_id, :fulfillment_id])
  end
end
