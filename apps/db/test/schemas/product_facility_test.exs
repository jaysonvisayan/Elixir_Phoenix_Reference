defmodule Innerpeace.Db.Schemas.ProductFacilityTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.ProductFacility

  test "changeset with valid attributes" do
    params = %{
      facility_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      product_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      is_included: true,
      coverage_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
    }

    changeset = ProductFacility.changeset(%ProductFacility{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      facility_id: "",
      product_id: "",
      is_included: nil
    }

    changeset = ProductFacility.changeset(%ProductFacility{}, params)
    refute changeset.valid?
  end
end
