defmodule Innerpeace.Db.Schemas.AccountGroupFulfillmentTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.AccountGroupFulfillment

  test "changeset with valid attributes" do
    params = %{
      account_group_id: Ecto.UUID.generate(),
      fulfillment_id: Ecto.UUID.generate()
    }

    changeset = AccountGroupFulfillment.changeset(%AccountGroupFulfillment{}, params)
    assert changeset.valid?

  end
end
