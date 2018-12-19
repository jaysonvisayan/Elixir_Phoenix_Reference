defmodule Innerpeace.Db.ApplicationSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.ApplicationSeeder
  @name "PayorLink"

  test "seed user with new data" do
    [a1] = ApplicationSeeder.seed(data())
    assert a1.name == @name
  end

  test "seed user with existing data" do
    insert(:application, name: @name)
    data = [
      %{
        name: "AccountLink"
      }
    ]
    [a1] = ApplicationSeeder.seed(data)
    assert a1.name == "AccountLink"
  end

  defp data do
    [
      %{
        name: @name
      }
    ]
  end

end
