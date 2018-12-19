defmodule Innerpeace.Db.UserRoleSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.UserRoleSeeder


  test "seed user with new data" do
    u = insert(:user, username: "admin")
    r1 = insert(:role, name: "CEO")
    [ur1] = UserRoleSeeder.seed(data(u,r1))
    assert ur1.user_id == u.id
    assert ur1.role_id == r1.id
  end

  test "seed user with existing data" do
    u = insert(:user, username: "admin")
    r1 = insert(:role, name: "CEO")
    _data = [
       %{
         user_id: u.id
       }
     ]
     [r1] = UserRoleSeeder.seed(data(u,r1))
     assert r1.user_id == u.id
   end

  defp data(u,r) do
    [
      %{
        user_id: u.id,
        role_id: r.id
      }
    ]
  end

end
