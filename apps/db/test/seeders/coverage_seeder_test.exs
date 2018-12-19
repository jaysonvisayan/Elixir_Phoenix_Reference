defmodule Innerpeace.Db.CoverageSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.CoverageSeeder
  @name "OP Consult"

  test "seed user with new data" do
    [c1] = CoverageSeeder.seed(data())
    assert c1.name == @name
  end

  test "seed user with existing data" do
    insert(:coverage, name: @name)
    data = [
      %{
        name: "OP Laboratory"
      }
    ]
    [c1] = CoverageSeeder.seed(data)
    assert c1.name == "OP Laboratory"
  end

  defp data do
    [
      %{
        name: @name
      }
    ]
  end

end
