defmodule Innerpeace.Db.BankSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.BankSeeder
  @account_name "Metropolitan Bank and Trust Company"

  test "seed bank with new data" do
    account_group = insert(:account_group)
    [b1] = BankSeeder.seed(data(account_group))
    assert b1.account_name == @account_name
  end

  test "seed bank with existing data" do
    account_group = insert(:account_group)
    data = [
      %{
        account_name: "Metropolitan Bank and Trust Company",
        account_no: "00001",
        account_status: "Active",
        account_group_id: account_group.id
      }
    ]
    [b1] = BankSeeder.seed(data)
    assert b1.account_name == @account_name
  end

  defp data(account_group) do
    [
      %{
      account_name: "Metropolitan Bank and Trust Company",
      account_no: "00001",
      account_status: "Active",
      account_group_id: account_group.id

      }
    ]

  end


end
