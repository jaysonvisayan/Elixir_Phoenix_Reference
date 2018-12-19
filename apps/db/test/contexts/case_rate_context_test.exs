defmodule Innerpeace.Db.Base.CaseRateContextTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.{
    CaseRate
    # Diagnosis,
    # RUV,
    # CaseRateLog
  }
  alias Innerpeace.Db.Base.CaseRateContext

  @invalid_attrs %{}

  test "lists all case_rate" do
    case_rate = insert(:case_rate)
    case_rate =
      case_rate
      |> Repo.preload([:case_rate_log])
    assert CaseRateContext.get_all_case_rate() == [case_rate]
  end

  test "get_case_rate returns the case_rate with given id" do
    case_rate = insert(:case_rate, type: "RUV")
    case_rate =
      case_rate
      |> Repo.preload([:case_rate_log])
    assert CaseRateContext.get_case_rate(case_rate.id) == case_rate
  end

  test "create_case_rate with valid data creates an case_rate" do
    diagnosis = insert(:diagnosis)
    params = %{
      type: "ICD",
      hierarchy1: 1,
      discount_percentage1: 100,
      description: "NONE",
      diagnosis_id: diagnosis.id
    }
    assert {:ok, %CaseRate{} = case_rate} = CaseRateContext.create_case_rate(params)
    assert case_rate.type == "ICD"
  end

  test "create_case_rate with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = CaseRateContext.create_case_rate(@invalid_attrs)
  end

  test "update_case_rate with valid data updates the case_rate" do
    case_rate = insert(:case_rate)
    ruv = insert(:ruv)
    params = %{
      type: "RUV",
      hierarchy1: 1,
      discount_percentage1: 100,
      description: "NOTHING",
      ruv_id: ruv.id
    }
    assert {:ok, case_rate} = CaseRateContext.update_case_rate(case_rate.id, params)
    assert %CaseRate{} = case_rate
    assert case_rate.type == "RUV"
  end

  test "update_case_rate with invalid data returns error changeset" do
    case_rate = insert(:case_rate)
    case_rate =
      case_rate
      |> Repo.preload([:case_rate_log])
    assert {:error, %Ecto.Changeset{}} = CaseRateContext.update_case_rate(case_rate.id, @invalid_attrs)
    assert case_rate == CaseRateContext.get_case_rate(case_rate.id)
  end

  test "delete_case_rate deletes the case_rate" do
    case_rate = insert(:case_rate)
    assert {:ok, %CaseRate{}} = CaseRateContext.delete_case_rate(case_rate.id)
    assert_raise Ecto.NoResultsError, fn -> CaseRateContext.get_case_rate(case_rate.id) end
  end

end
