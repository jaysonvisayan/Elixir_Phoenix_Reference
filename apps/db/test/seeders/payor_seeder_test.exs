defmodule Innerpeace.Db.PayorSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.PayorSeeder
  @name "Maxicare"

  test "seed payor with new data" do
    [pa1] = PayorSeeder.seed(data())
    assert pa1.name == @name
  end

  test "seed payor with existing data" do
    insert(:payor, name: @name)
    data = [
      %{
        name: "Caritas Health Shield"
      }
    ]
    [pa1] = PayorSeeder.seed(data)
    assert pa1.name == "Caritas Health Shield"
  end

  defp data do
    [
      %{
        name: @name
      }
    ]
  end

end
