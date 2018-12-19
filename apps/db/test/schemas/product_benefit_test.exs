defmodule Innerpeace.Db.Schemas.ProductBenefitTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.ProductBenefit

  test "changeset with valid attributes" do
    params = %{
      product_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      benefit_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      limit_type: "test type",
      limit_value: 1,
    }

    changeset = ProductBenefit.changeset(%ProductBenefit{}, params)
    assert changeset.valid?

  end

  test "changeset with invalid attributes" do
    params = %{
      product_id: "",
      benefit_id: "",
      limit_type: "",
      limit_value: 0,
    }

    changeset = ProductBenefit.changeset(%ProductBenefit{}, params)
    refute changeset.valid?
  end
end
