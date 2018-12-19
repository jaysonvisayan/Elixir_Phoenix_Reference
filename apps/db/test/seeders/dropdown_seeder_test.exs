defmodule Innerpeace.Db.DropdownSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.DropdownSeeder


  test "test dropdown with new data" do
    [d1] = DropdownSeeder.seed(data())
    assert d1.value == "DP"
  end

  test "test dropdown with existing data" do
    insert(:dropdown)
    data = [
      %{
        type: "Facility Type",
        value: "DP",
        text: "DENTAL PROVIDER"
      }

    ]
    [d1] = DropdownSeeder.seed(data)
    assert d1.value == "DP"
  end


  defp data do
    [
      %{
        type: "Facility Type",
        value: "DP",
        text: "DENTAL PROVIDER"
      }
    ]
  end





end

