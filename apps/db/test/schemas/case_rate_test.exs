defmodule Innerpeace.Db.Schemas.CaseRateTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.CaseRate

  test "diagnosis changeset with valid attributes" do
    diagnosis = insert(:diagnosis)
    insert(:case_rate)
    params = %{
      code: "CODE1",
      type: "ICD",
      description: "SAMPLE",
      hierarchy: 1,
      discount_percentage: 100,
      diagnosis_id: diagnosis.id
    }

    changeset = CaseRate.changeset(%CaseRate{}, params)
    assert changeset.valid?
  end

  test "ruv changeset with valid attributes" do
    ruv = insert(:ruv)
    insert(:case_rate)
    params = %{
      code: "CODE1",
      type: "ICD",
      description: "SAMPLE",
      hierarchy: 1,
      discount_percentage: 100,
      ruv_id: ruv.id
    }

    changeset = CaseRate.changeset(%CaseRate{}, params)
    assert changeset.valid?
  end

  test "diagnosis changeset with invalid attributes" do
    params = %{
      code: "CODE1"
    }
    changeset = CaseRate.changeset(%CaseRate{}, params)

    refute changeset.valid?
  end

  test "ruv changeset with invalid attributes" do
    params = %{
      code: "CODE1"
    }
    changeset = CaseRate.changeset(%CaseRate{}, params)

    refute changeset.valid?
  end
end
