defmodule Innerpeace.Db.UserSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.UserSeeder
  @username "user1"
  @email "user@demo.com"

  test "seed user with new data" do
    [u1] = UserSeeder.seed(data())
    assert u1.username == @username
  end

  test "seed user with existing data" do
    insert(:user, username: @username, email: @email)
    [u1] = UserSeeder.seed(data())
    assert u1.username == @username
  end

  defp data do
    [
      %{
        username: @username,
        password: "P@ssw0rd",
        password_confirmation: "P@ssw0rd",
        first_name: "user",
        last_name: "test",
        is_admin: false,
        email: @email,
        gender: "male",
        mobile: "11111111111"
      }
    ]
  end

end
