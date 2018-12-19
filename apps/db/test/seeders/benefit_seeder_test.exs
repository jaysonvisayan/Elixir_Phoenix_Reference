defmodule Innerpeace.Db.BenefitSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.BenefitSeeder
  @code_health "B102"
  @code_riders "B101"
  @name_health "Medilink Benefit"
  @name_riders "Accenture Benefit"
  @category_health "Health"
  @category_riders "Riders"
  @step 5

  test "seed_health benefit with new data_health" do
    user = insert(:user)
    coverage = insert(:coverage)
    [a1] = BenefitSeeder.seed_health(data_health(coverage,user))
    assert a1.code == @code_health
  end

  test "seed_health benefit with existing data_health" do
    user = insert(:user)
    coverage = insert(:coverage)
    insert(:benefit)
    _data_health = [
      %{
        name: "Medilink Benefit"
      }
    ]
    [a1] = BenefitSeeder.seed_health(data_health(coverage,user))
    assert a1.name == "Medilink Benefit"
  end

  test "seed_riders benefit with new date_riders" do
    user = insert(:user)
    coverage = insert(:coverage)
    [a1] = BenefitSeeder.seed_riders(date_riders(coverage,user))
    assert a1.code == @code_riders
  end

  test "seed_riders benefit with existing date_riders" do
    user = insert(:user)
    coverage = insert(:coverage)
    insert(:benefit)
    _date_riders = [
      %{
        name: "Accenture Benefit 2"
      }
    ]
    [a1] = BenefitSeeder.seed_riders(date_riders(coverage,user))
    assert a1.name == "Accenture Benefit"
  end


  defp data_health(coverage, user) do
    [
      %{
        code: @code_health,
        name: @name_health,
        created_by_id: user.id,
        updated_by_id: user.id,
        category: @category_health,
        step: @step,
        coverage_ids: [coverage.id]
      }
    ]
  end

  defp date_riders(coverage, user) do
    [
      %{
        code: @code_riders,
        name: @name_riders,
        created_by_id: user.id,
        updated_by_id: user.id,
        category: @category_riders,
        step: @step,
        coverage_id: coverage.id
      }
    ]
  end
end
