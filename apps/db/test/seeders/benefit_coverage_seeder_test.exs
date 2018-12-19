defmodule Innerpeace.Db.BenefitCoverageSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.BenefitCoverageSeeder

  test "seed benefit coverage with new data" do
    benefit = insert(:benefit)
    coverage = insert(:coverage)
    [a1] = BenefitCoverageSeeder.seed(data(benefit,coverage))
    assert a1.benefit_id == benefit.id
  end

  test "seed benefit coverage with existing data" do
    benefit = insert(:benefit)
    coverage = insert(:coverage)
    insert(:benefit_coverage)
    data = [
      %{
        benefit_id: benefit.id,
        coverage_id: coverage.id
      }
    ]
    [a1] = BenefitCoverageSeeder.seed(data)
    assert a1.benefit_id == benefit.id
  end


  defp data(benefit, coverage) do
    [
      %{
         benefit_id: benefit.id,
         coverage_id: coverage.id
      }
    ]
  end

end
