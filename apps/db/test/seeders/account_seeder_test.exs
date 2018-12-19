defmodule Innerpeace.Db.AccountSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.AccountSeeder

  test "seed account with new data" do
    user = insert(:user)
    account_group = insert(:account_group)
    insert(:account)
    [a1] = AccountSeeder.seed(data(user,account_group))
    assert a1.account_group_id == account_group.id
  end

  test "seed user with existing data" do
    user = insert(:user)
    account_group = insert(:account_group)
    insert(:account)
    _data = [
      %{
        end_date: Ecto.Date.cast!("2018-09-01")
      }
    ]
    [a1] = AccountSeeder.seed(data(user,account_group))
    assert a1.account_group_id == account_group.id
  end

  defp data(user,account_group) do
    [
      %{
          start_date: Ecto.Date.cast!("2017-08-01"),
          end_date: Ecto.Date.cast!("2018-08-01"),
          status: "Active",
          account_group_id: account_group.id,
          major_version: 1,
          minor_version: 0,
          build_version: 0,
          updated_by: user.id,
          step: 6
      }
    ]
  end

end
