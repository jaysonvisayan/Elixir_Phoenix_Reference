defmodule Innerpeace.Db.Schemas.AccountGroupContactTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.AccountGroupContact

  test "changeset with valid attributes" do
    params = %{
      status: "test",
      type: "test",
      account_group_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      contact_id: "488412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = AccountGroupContact.changeset(%AccountGroupContact{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      status: "test",
      type: "test",
      account_group_id: "",
      contact_id: "488412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = AccountGroupContact.changeset(%AccountGroupContact{}, params)
    refute changeset.valid?
  end
end
