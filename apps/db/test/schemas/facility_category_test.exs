defmodule Innerpeace.Db.Schemas.FacilityCategoryTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.FacilityCategory

  test "changeset with valid attributes" do
    params = %{
      type: "asd",
    }

    changeset = FacilityCategory.changeset(%FacilityCategory{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      type: "",
    }

    changeset = FacilityCategory.changeset(%FacilityCategory{}, params)
    refute changeset.valid?
  end
end
