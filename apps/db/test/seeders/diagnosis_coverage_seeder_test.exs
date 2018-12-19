defmodule Innerpeace.Db.DiagnosisCoverageSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.DiagnosisCoverageSeeder

  test "seed diagnosis coverage with new data" do
    coverage = insert(:coverage)
    diagnosis = insert(:diagnosis)
    [a1] = DiagnosisCoverageSeeder.seed(data(diagnosis,coverage))
    assert a1.diagnosis_id == diagnosis.id
  end

  test "seed diagnosis coverage with existing data" do
    coverage = insert(:coverage)
    diagnosis = insert(:diagnosis)
    insert(:diagnosis_coverage)
    data = [
      %{
        coverage_id: coverage.id,
        diagnosis_id: diagnosis.id
      }
    ]
    [a1] = DiagnosisCoverageSeeder.seed(data)
    assert a1.coverage_id == coverage.id
  end


  defp data(diagnosis,coverage) do
    [
      %{
         coverage_id: coverage.id,
         diagnosis_id: diagnosis.id
      }
    ]
  end

end
