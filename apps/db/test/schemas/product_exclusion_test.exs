defmodule Innerpeace.Db.Schemas.ProductExclusionTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.ProductExclusion

  test "changeset_genex with valid attributes" do
    params = %{
      product_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      exclusion_id: "388412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = ProductExclusion.changeset_genex(%ProductExclusion{}, params)
    assert changeset.valid?
  end

  test "changeset_genex with invalid attributes" do
    params = %{
      product_id: "",
      exclusion_id: ""
    }

    changeset = ProductExclusion.changeset_genex(%ProductExclusion{}, params)
    refute changeset.valid?
  end

  test "changeset_pre_existing with valid attributes" do
    params = %{
      product_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      exclusion_id: "388412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = ProductExclusion.changeset_pre_existing(%ProductExclusion{}, params)
    assert changeset.valid?
  end

  test "changeset_pre_existing with invalid attributes" do
    params = %{
      product_id: "",
      exclusion_id: ""
    }

    changeset = ProductExclusion.changeset_pre_existing(%ProductExclusion{}, params)
    refute changeset.valid?
  end
end
