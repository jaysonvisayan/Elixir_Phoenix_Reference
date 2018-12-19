defmodule Innerpeace.Db.Schemas.ProductBenefitCoverageTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.ProductBenefitCoverage

  test "changeset with valid attributes" do
    params = %{
      product_benefit_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      coverage_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
    }

    changeset = ProductBenefitCoverage.changeset(% ProductBenefitCoverage{}, params)
    assert changeset.valid?

  end

  test "changeset with invalid attributes" do
    params = %{
      product_benefit_id: "",
      coverage_id: ""
    }

    changeset = ProductBenefitCoverage.changeset(%ProductBenefitCoverage{}, params)
    refute changeset.valid?
  end
end
