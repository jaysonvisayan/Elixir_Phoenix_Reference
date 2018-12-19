defmodule Innerpeace.Db.Validator.IPValidatorTest do
  use Innerpeace.Db.SchemaCase, async: false

  setup do
    user = insert(:user)
    account_group = insert(:account_group, name: "ACCOUNT101", code: "ACC101")
    insert(:member, %{
      first_name: "Joseph",
      last_name: "Canilao",
      card_no: "123456789012",
      account_group: account_group,
      effectivity_date: Ecto.Date.cast!("2011-11-10")
    })

    # room = insert(:)

    {:ok, %{user: user}}
  end

  test "inpatient", %{user: _user} do

  end

end
