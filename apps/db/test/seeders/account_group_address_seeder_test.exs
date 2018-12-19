defmodule Innerpeace.Db.AccountGroupAddressSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.AccountGroupAddressSeeder

  test "seed account_group_address_address with new data" do
    insert(:account_group_address)
    account_group = insert(:account_group)
    [a1] = AccountGroupAddressSeeder.seed(data(account_group))
    assert a1.account_group_id == account_group.id
  end

  test "seed user with existing data" do
    account_group = insert(:account_group)
    insert(:account_group_address)
    update_data = [
      %{
          account_group_id: account_group.id,
          line_1: "Ade",
          line_2: "624",
          postal_code: "1001",
          city: "Paterno Street Quiapo Manila 2",
          type: "Account Address",
          province: "Metro Manila",
          region: "NCR"
      }
    ]
    [a1] = AccountGroupAddressSeeder.seed(update_data)
    assert a1.account_group_id == account_group.id
  end

  defp data(account_group) do
    [
      %{
          account_group_id: account_group.id,
          line_1: "Ade",
          line_2: "624",
          postal_code: "4232",
          city: "Paterno Street Quiapo Manila",
          country: "Philippines",
          type: "Account Address",
          province: "Metro Manila",
          is_check: true,
          region: "NCR"
      }
    ]
  end

end
