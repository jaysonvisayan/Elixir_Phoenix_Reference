defmodule Innerpeace.Db.RoleSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.RoleSeeder
  @name "UEF Processor"
  # @description "this is a sample role"
  # @step 4

  test "seed user with new data" do
    u = insert(:user, username: "admin")
    [r1] = RoleSeeder.seed(data(u))
    assert r1.name == @name
  end

  test "seed user with existing data" do
    u = insert(:user, username: "admin",
    password: "P@ssw0rd",
    is_admin: true,
    email: "admin@gmail.com",
    mobile: "09199046601",
    first_name: "Admin",
    middle_name: "is",
    last_name: "trator",
    gender: "Male"
)
    _data = [
       %{
         name: "UEF Supervisor"
       }
     ]
     [r1] = RoleSeeder.seed(data(u))
     assert r1.name == "UEF Processor"
   end

  defp data(u) do
    [
      %{
        name: "UEF Processor",
        description: "this is a sample role",
        step: 4,
        user_id: u.id,
      }
    ]
  end

end
