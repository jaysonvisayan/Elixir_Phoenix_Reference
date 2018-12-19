defmodule Innerpeace.Db.Schemas.AccountProductTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.AccountProduct

  test "changeset with valid attributes" do
    params = %{
      account_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      product_id: "488412e1-1668-42b7-86d2-bd57f46678b6",
      name: "name",
      description: "description",
      type: "type",
      limit_type: "limit_type",
      limit_amount: 12_000,
      limit_applicability: "Applicability"
    }

    changeset = AccountProduct.changeset(%AccountProduct{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      product_id: "488412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = AccountProduct.changeset(%AccountProduct{}, params)
    refute changeset.valid?
  end

end
