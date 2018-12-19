defmodule Innerpeace.Db.Base.CoverageContextTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.{
    Coverage
  }
  alias Innerpeace.Db.Base.{
    CoverageContext
  }

  test "get_all_coverages with result" do
    # Setup
    coverage = insert(:coverage)

    # Logic
    result = CoverageContext.get_all_coverages()

    # Assertions
    assert result == [coverage]
  end

  test "get_all_coverages with 2 results" do
    # Setup
    insert(:coverage)
    insert(:coverage)

    # Logic
    result = CoverageContext.get_all_coverages()

    # Assertions
    assert Enum.count(result) == 2
  end

  test "get_coverage/1 returns the coverage with the given id" do
    coverage = insert(:coverage)
    assert CoverageContext.get_coverage(coverage.id) == coverage
  end

  test "create_coverage/1 with valid data creates a coverage" do
    # Setup
    params = %{
      name: "ACU",
      description: "test",
      status: "pending",
      type: "test",
      plan_type: "wat",
      code: "yo"
    }

    # Logic
    {status, result} = CoverageContext.create_coverage(params)

    # Assertions
    assert status == :ok
    assert result.name == params.name
  end

  test "create_coverage/1 with invalid data returns error changeset" do
    coverage_params = %{
      name: nil,
      description: nil,
      status: nil,
      type: nil
    }
    assert {:error, %Ecto.Changeset{}} = CoverageContext.create_coverage(coverage_params)
  end

  test "update_coverage with valid params" do
    # Setup
    c = insert(:coverage, name: "OPConsult")
    params = %{
      name: "ACU",
      description: "test",
      status: "pending",
      type: "test",
      plan_type: "wat",
      code: "yo"
    }

    # Logic
    {status, result} = CoverageContext.update_coverage(c.id, params)

    # Assertions
    assert status == :ok
    assert result.name == params.name
  end

  test "update_coverage/2 with invalid data returns error changeset" do
    coverage = insert(:coverage)
    coverage_params = %{
      name: nil,
      description: nil,
      status: nil,
      type: nil
    }
    assert {:error, %Ecto.Changeset{}} = CoverageContext.update_coverage(coverage.id, coverage_params)
    assert coverage == CoverageContext.get_coverage(coverage.id)
  end

  test "delete_coverage/1 deletes the coverage" do
    coverage = insert(:coverage)
    assert {:ok, %Coverage{}} = CoverageContext.delete_coverage(coverage.id)
    assert_raise Ecto.NoResultsError, fn -> CoverageContext.get_coverage(coverage.id) end
  end

end
