defmodule Innerpeace.Db.IndustrySeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.IndustrySeeder
  @code "A01 - ADVERTISING"

  test "seed industry with new data" do
    [a1] = IndustrySeeder.seed(data())
    assert a1.code == @code
  end

  test "seed user with existing data" do
    insert(:industry, code: @code)
    data = [
      %{
        code: "A02 - AGRICULTURAL SERVICES"
      }
    ]
    [a1] = IndustrySeeder.seed(data)
    assert a1.code == "A02 - AGRICULTURAL SERVICES"
  end

  defp data do
    [
      %{
        code: @code
      }
    ]
  end

end
