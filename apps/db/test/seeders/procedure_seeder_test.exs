defmodule Innerpeace.Db.ProcedureSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.ProcedureSeeder
  @code "00100-01999"
  @description "HYDROXYPROGESTERONE, 17-D"

  test "seed procedure with new data" do
    procedure_category = insert(:procedure_category, name: "Pathology and Laboratory Procedures")
    [a1] = ProcedureSeeder.seed(data(procedure_category))
    assert a1.code == @code
  end

  test "seed procedure with existing data" do
    procedure_category = insert(:procedure_category, name: "Pathology and Laboratory Procedures")
    insert(:procedure)
    data = [
      %{
        code: "88271",
        description: "MOLECULAR CYTOGENETICS; DNA PROBE, EACH (EG, FISH)",
        type: "Diagnostic",
        procedure_category_id: procedure_category.id
      }
    ]
    [a1] = ProcedureSeeder.seed(data)
    assert a1.description == "MOLECULAR CYTOGENETICS; DNA PROBE, EACH (EG, FISH)"
  end


  defp data(procedure_category) do
    [
      %{
         code: @code,
         description: @description,
         type: "Diagnostic",
         procedure_category_id: procedure_category.id
      }
    ]
  end

end
