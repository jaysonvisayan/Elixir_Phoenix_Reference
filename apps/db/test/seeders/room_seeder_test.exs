defmodule Innerpeace.Db.RoomSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.RoomSeeder

  test "seed room with new data" do
    [a1] = RoomSeeder.seed(data())
    assert a1.code == "REGROOM101"
  end

  test "seed room with existing data" do
    insert(:room, code: "PRIVROOM101" , type: "Private Room")
    data = [
      %{
        code: "PRIVROOM102",
        type: "Private Room 2",
        hierarchy: 1,
        ruv_rate: "1000"
      }
    ]
    [a1] = RoomSeeder.seed(data)
    assert a1.type == "Private Room 2"
  end

  defp data do
    [
      %{
        code: "REGROOM101",
        type: "Regular Room",
        hierarchy: 1,
        ruv_rate: "1000"
      }
    ]
  end

end
