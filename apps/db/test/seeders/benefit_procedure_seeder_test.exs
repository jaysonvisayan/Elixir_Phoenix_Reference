defmodule Innerpeace.Db.BenefitDiagnosisProcedureTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.BenefitProcedureSeeder

  test "seed benefit procedure with new data" do
    benefit = insert(:benefit)
    procedure = insert(:payor_procedure)
    [a1] = BenefitProcedureSeeder.seed(data(benefit,procedure))
    assert a1.benefit_id == benefit.id
  end

  test "seed benefit procedure with existing data" do
    benefit = insert(:benefit)
    procedure = insert(:payor_procedure)
    insert(:benefit_procedure)
    data = [
      %{
        benefit_id: benefit.id,
        procedure_id: procedure.id
      }
    ]
    [a1] = BenefitProcedureSeeder.seed(data)
    assert a1.benefit_id == benefit.id
  end


  defp data(benefit, procedure) do
    [
      %{
         benefit_id: benefit.id,
         procedure_id: procedure.id
      }
    ]
  end

end
