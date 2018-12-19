defmodule Innerpeace.Db.Schemas.ProductRiskShareTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.ProductRiskShare

  test "changeset with valid attributes" do
    params = %{
      product_id: Ecto.UUID.generate(),
      coverage_id: Ecto.UUID.generate(),
      fund: "aso",
      af_type: "Reimbursement",
      af_value: 10000,
      af_covered: 10000,
      naf_reimbursable: "Yes",
      naf_type: "Co-Payment",
      naf_value: 100,
      naf_covered: 10,
    }

    changeset = ProductRiskShare.changeset(%ProductRiskShare{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      product_id: nil,
      coverage_id: nil,
      fund: "aso",
      af_type: "Reimbursement",
      af_value: 10000,
      af_covered: 10000,
      naf_reimbursable: "Yes",
      naf_type: "Co-Payment",
      naf_value: 100,
      naf_covered: 10,
    }

    changeset = ProductRiskShare.changeset(%ProductRiskShare{}, params)
    refute changeset.valid?
  end
end
