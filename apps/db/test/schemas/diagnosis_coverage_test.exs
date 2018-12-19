defmodule Innerpeace.Db.Schemas.DiagnosisCoverageTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.DiagnosisCoverage

  test "changeset with valid attributes" do
    params = %{
      coverage_id: Ecto.UUID.generate(),
      diagnosis_id: Ecto.UUID.generate()
    }

    changeset = DiagnosisCoverage.changeset(%DiagnosisCoverage{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      coverage_id: "",
      diagnosis_id: ""
    }

    changeset = DiagnosisCoverage.changeset(%DiagnosisCoverage{}, params)
    refute changeset.valid?
  end

end
