defmodule Innerpeace.Db.Schemas.ExclusionTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Exclusion

  test "changeset exclusion with valid attributes" do
    params = %{
      code: "some code",
      name: "some name",
      coverage: "General Exclusion"
    }
    changeset = Exclusion.changeset_exclusion(%Exclusion{}, params)
    assert changeset.valid?
  end

  test "changeset exclusion with invalid attributes" do
    params = %{}
    changeset = Exclusion.changeset_exclusion(%Exclusion{}, params)
    refute changeset.valid?
  end

  test "changeset pre existing with valid attributes" do
    params = %{
      code: "some code",
      name: "some name",
      coverage: "Pre-existing Condition",
      duration_from: "2012-12-18",
      duration_to: "2012-12-25"
    }
    changeset = Exclusion.changeset_pre_existing(%Exclusion{}, params)
    assert changeset.valid?
  end

  test "changeset pre existing with invalid attributes" do
    params = %{}
    changeset = Exclusion.changeset_pre_existing(%Exclusion{}, params)
    refute changeset.valid?
  end

end
