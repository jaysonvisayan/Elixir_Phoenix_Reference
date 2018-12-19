defmodule Innerpeace.Db.PermissionSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.PermissionSeeder
  @name "Manage Accounts"
  @module "Accounts"
  @keyword "manage_accounts"

  test "seed user with new data" do
    a = insert(:application, name: "PayorLink")
    [p1] = PermissionSeeder.seed(data(a))
    assert p1.name == @name
  end

  test "seed user with existing data" do
    a = insert(:application, name: "PayorLink")
    insert(:permission, name: @name, module: @module, keyword: @keyword, application_id: a.id, status: "sample",description: "sample")
     _data = [
       %{
         name: "Manage Accounts"
       }
     ]
     [p1] = PermissionSeeder.seed(data(a))
     assert p1.name == "Manage Accounts"
   end

  defp data(a) do
    [
      %{
        name: @name,
        module: @module,
        keyword: @keyword,
        application_id: a.id,
        status: "sample",
        description: "sample"
      }
    ]
  end

end
