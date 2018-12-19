defmodule Innerpeace.Db.Schemas.AccountHierarchyOfEligibleDependentTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.AccountHierarchyOfEligibleDependent

  test "changeset with valid attributes" do
    account_group = insert(:account_group)
    params = %{
      account_group_id: account_group.id,
      hierarchy_type: "Married Employee",
      dependent: "Spouse",
      ranking: 1
    }

    changeset = AccountHierarchyOfEligibleDependent.changeset(%AccountHierarchyOfEligibleDependent{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      account_id: 123,
      dependent: "Spouse",
      ranking: 1
    }

    changeset = AccountHierarchyOfEligibleDependent.changeset(%AccountHierarchyOfEligibleDependent{}, params)
    refute changeset.valid?
  end
end
