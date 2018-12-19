defmodule Innerpeace.Db.ProcedureCategorySeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.ProcedureCategorySeeder
  @name "Anesthesia"
  @code "00100-01999"

  test "seed procedure category with new data" do
    [a1] = ProcedureCategorySeeder.seed(data())
    assert a1.name == @name
  end

  test "seed procedure category with existing data" do
    insert(:procedure_category, name: @name)
    data = [
      %{
        name: "Surgery",
        code: "10021-69990"
      }
    ]
    [a1] = ProcedureCategorySeeder.seed(data)
    assert a1.name == "Surgery"
  end

  defp data do
    [
      %{
        name: @name,
        code: @code
      }
    ]
  end

end
