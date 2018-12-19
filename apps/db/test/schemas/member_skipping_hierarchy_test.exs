defmodule Innerpeace.Db.Schemas.MemberSkippingHierarchyTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.MemberSkippingHierarchy

  test "changeset with valid attributes" do
    params = %{
      member_id: Ecto.UUID.generate(),
      first_name: "anton",
      last_name: "santiago",
      gender: "Male",
      relationship: "Parent",
      birthdate: "1995-12-18",
      reason: "no reason"
    }
    changeset = MemberSkippingHierarchy.changeset(%MemberSkippingHierarchy{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = MemberSkippingHierarchy.changeset(%MemberSkippingHierarchy{})
    refute changeset.valid?
  end

  test "changeset_approve with valid attributes" do
    params = %{
      status: "Approve"
    }
    changeset = MemberSkippingHierarchy.changeset_approve(%MemberSkippingHierarchy{}, params)
    assert changeset.valid?
  end

  test "changeset_approve with invalid attributes" do
    changeset = MemberSkippingHierarchy.changeset_approve(%MemberSkippingHierarchy{})
    refute changeset.valid?
  end

end

