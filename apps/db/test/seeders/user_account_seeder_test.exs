defmodule Innerpeace.Db.UserAccountSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.UserAccountSeeder


  test "seed user with new data" do
    u = insert(:user, username: "admin")
    a = insert(:account_group, name: "account")
    [ua1] = UserAccountSeeder.seed(data(u,a))
    assert ua1.user_id == u.id
    assert ua1.account_group_id == a.id
  end

  test "seed user with existing data" do
    u = insert(:user, username: "admin")
    a = insert(:account_group, name: "account")
    insert(:user_account, user_id: u.id, account_group_id: a.id)
     data = [
       %{
         user_id: u.id,
        account_group_id: a.id
       }
     ]
     [ua1] = UserAccountSeeder.seed(data)
    assert ua1.user_id == u.id
    assert ua1.account_group_id == a.id
   end

  defp data(u,a) do
    [
      %{
        user_id: u.id,
        account_group_id: a.id
      }
    ]
  end

end
