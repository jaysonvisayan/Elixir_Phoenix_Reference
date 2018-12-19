defmodule Innerpeace.Db.Schemas.AccountGroupTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.AccountGroup

  test "changeset with valid attributes" do
    industry = insert(:industry)
    params = %{
      name: "AccountGroupTest",
      type: "Type1",
      code: "Code1",
      description: "DescriptionTest",
      segment: "Corporate",
      phone_no: "09210042020",
      email: "admin@example.com",
      industry_id: industry.id,
      original_effective_date: Ecto.Date.cast!("2017-08-01")
    }

    changeset = AccountGroup.changeset(%AccountGroup{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      name: "Account1"
    }
    changeset = AccountGroup.changeset(%AccountGroup{}, params)

    refute changeset.valid?
  end
end
