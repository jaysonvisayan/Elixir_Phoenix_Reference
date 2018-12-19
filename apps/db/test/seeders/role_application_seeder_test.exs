defmodule Innerpeace.Db.RoleApplicationSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.RoleApplicationSeeder


  test "seed role_application with new data" do
    r = insert(:role, name: "admin")
    a = insert(:application, name: "PayorLink")
    [ra1] = RoleApplicationSeeder.seed(data(r,a))
    assert ra1.role_id == r.id
    assert ra1.application_id == a.id
  end

  defp data(r,a) do
    [
      %{
        role_id: r.id,
        application_id: a.id
      }
    ]
  end

end
