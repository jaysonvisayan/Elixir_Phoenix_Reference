defmodule Innerpeace.Db.RolePermissionSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.RolePermissionSeeder


  test "seed user with new data" do
    r = insert(:role, name: "admin")
    p = insert(:permission, name: "Manage Accounts")

    [rp1] = RolePermissionSeeder.seed(data(r,p))
    assert rp1.role_id == r.id
    assert rp1.permission_id == p.id
  end



  defp data(r,p) do
    [
      %{
        role_id: r.id,
        permission_id: p.id
      }
    ]
  end

end
