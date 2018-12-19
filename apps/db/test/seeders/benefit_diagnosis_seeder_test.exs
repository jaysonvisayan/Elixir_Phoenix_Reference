defmodule Innerpeace.Db.BenefitDiagnosisSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.BenefitDiagnosisSeeder

  test "seed benefit diagnosis with new data" do
    benefit = insert(:benefit)
    diagnosis = insert(:diagnosis)
    [a1] = BenefitDiagnosisSeeder.seed(data(benefit,diagnosis))
    assert a1.benefit_id == benefit.id
  end

  test "seed benefit diagnosis with existing data" do
    benefit = insert(:benefit)
    diagnosis = insert(:diagnosis)
    insert(:benefit_diagnosis)
    data = [
      %{
        benefit_id: benefit.id,
        diagnosis_id: diagnosis.id
      }
    ]
    [a1] = BenefitDiagnosisSeeder.seed(data)
    assert a1.benefit_id == benefit.id
  end


  defp data(benefit, diagnosis) do
    [
      %{
         benefit_id: benefit.id,
         diagnosis_id: diagnosis.id
      }
    ]
  end

end
