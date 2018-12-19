defmodule Innerpeace.Db.Schemas.ProductBenefitLimitTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.ProductBenefitLimit

  test "changeset with valid attributes" do
    params = %{
      product_benefit_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      benefit_limit_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      coverages: "OPC, OPL",
      limit_type: "Plan Limit Percentage",
      limit_amount: 20,
      limit_percentage: nil,
      limit_session: nil
    }

    changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{}, params)
    assert changeset.valid?

  end

  test "changeset with invalid attributes" do
    params = %{
      product_benefit_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      benefit_limit_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      coverages: nil,
      limit_type: "Percentage of Plan Limit",
      limit_amount: 20,
      limit_percentage: "",
      limit_session: ""
    }

    changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{}, params)
    refute changeset.valid?
  end
end
