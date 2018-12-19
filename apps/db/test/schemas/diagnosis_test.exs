defmodule Innerpeace.Db.Schemas.DiagnosisTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Diagnosis

  test "changeset with valid attributes" do
    params = %{
      code: "code",
      name: "name",
      classification: "administrator",
      type: "test",
      description: "test_description",
      group_description: "group",
      congenital: "test",
      exclusion_type: "Exclusion"
    }

    changeset = Diagnosis.changeset(%Diagnosis{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
    }

    changeset = Diagnosis.changeset(%Diagnosis{}, params)
   refute changeset.valid?
  end

end
