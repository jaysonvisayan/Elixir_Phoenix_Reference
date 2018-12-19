defmodule Innerpeace.Db.AccountGroupContactSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.AccountGroupContactSeeder

  test "seed with new data" do
    account_group = insert(:account_group)
    contact = insert(:contact)
    [a1] = AccountGroupContactSeeder.seed(data(account_group,contact))
    assert a1.account_group_id == account_group.id
  end

  test "seed with existing data" do
    account_group = insert(:account_group)
    contact = insert(:contact)
    insert(:account_group_contact)
    update_data = [
      %{
        account_group_id: account_group.id,
        contact_id: contact.id
      }
    ]
    [a1] = AccountGroupContactSeeder.seed(update_data)
    assert a1.account_group_id == account_group.id
  end

  defp data(account_group, contact) do
    [
      %{
        account_group_id: account_group.id,
        contact_id: contact.id
      }
    ]
  end

end
