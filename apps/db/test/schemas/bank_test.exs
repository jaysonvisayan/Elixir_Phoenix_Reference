defmodule Innerpeace.Db.Schemas.BankTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Bank

  test "changeset with valid attributes" do
    params = %{
      account_name: "some content",
      account_no: "199999",
      account_group_id: "1ad41ff9-eb03-4df3-90ab-c8f75db8a01e"
    }

    changeset = Bank.changeset(%Bank{}, params)
    assert changeset.valid?
  end

end

