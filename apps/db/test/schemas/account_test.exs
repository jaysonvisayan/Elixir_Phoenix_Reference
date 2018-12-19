defmodule Innerpeace.Db.Schemas.AccountTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Account

  test "changeset with valid attributes" do
    industry = insert(:industry)
    account_group = insert(:account_group)
    params = %{
      name: "AccountTest2",
      type: "type",
      code: "Code1",
      start_date: Ecto.Date.cast!("2017-01-01"),
      end_date: Ecto.Date.cast!("2017-01-10"),
      segment: "Corporate",
      phone_no: "09210042020",
      email: "admin@example.com",
      industry_id: industry.id,
      organization_id: industry.id,
      account_group_id: account_group.id,
      step: 1,
      created_by: industry.id,
      updated_by: industry.id
    }

    changeset = Account.changeset(%Account{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      name: "Account1",
      type: "Type",
      code: "plan_001",
      start_date: "test",
      end_date: Ecto.Date.utc(),
      status: "Active"
    }
    changeset = Account.changeset(%Account{}, params)

    refute changeset.valid?
  end

  test "changeset_suspend_account with valid attributes"  do
    insert(:account)
    params = %{
      status: "Suspended",
      suspend_date: "2017-08-08",
      suspend_remarks: "remarks",
      suspend_reason: "others"
    }

    changeset = Account.changeset_suspend_account(%Account{}, params)
    assert changeset.valid?
  end

  test "changeset_suspend_account with invalid attributes" do
    params = %{
      status: "Active",
      suspend_date: "test",
      suspend_reason: "reason1"
    }

    changeset = Account.changeset_suspend_account(%Account{}, params)
    refute changeset.valid?
  end

  test "changeset_extend_account with valid attributes" do
    insert(:account)
    params = %{end_date: "2017-09-01"}

    changeset = Account.changeset_extend_account(%Account{}, params)
    assert changeset.valid?
  end

  test "changeset_extend_account with invalid attributes" do
    insert(:account)
    params = %{}

    changeset = Account.changeset_extend_account(%Account{}, params)
    refute changeset.valid?
  end
end
