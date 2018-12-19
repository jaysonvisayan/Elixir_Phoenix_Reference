defmodule Innerpeace.Db.SpecializationSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.SpecializationSeeder
  @name "Dentistry"

  test "seed specialization with new data" do
    [a1] = SpecializationSeeder.seed(data())
    assert a1.name == @name
  end

  test "seed user with existing data" do
    insert(:specialization, name: @name)
    data = [
      %{
        name: "Emergency Medicine"
      }
    ]
    [a1] = SpecializationSeeder.seed(data)
    assert a1.name == "Emergency Medicine"
  end

  defp data do
    [
      %{
        name: @name
      }
    ]
  end

end
