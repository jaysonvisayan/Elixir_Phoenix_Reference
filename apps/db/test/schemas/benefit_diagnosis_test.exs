defmodule Innerpeace.Db.Schemas.BenefitDiagnosisTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.BenefitDiagnosis

  test "changeset with valid attributes" do
    params = %{
      exclusion: "test",
      mark: "test",
      benefit_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      diagnosis_id: "488412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = BenefitDiagnosis.changeset(%BenefitDiagnosis{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      exclusion: "",
      mark: "",
      benefit_id: "",
      diagnosis_id: "488412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = BenefitDiagnosis.changeset(%BenefitDiagnosis{}, params)
    refute changeset.valid?
  end

end
