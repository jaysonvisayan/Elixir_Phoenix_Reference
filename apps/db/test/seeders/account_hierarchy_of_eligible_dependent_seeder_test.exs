defmodule Innerpeace.Db.AccountHierarchyOfEligibleDependentSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.AccountHierarchyOfEligibleDependentSeeder

  test "seed account hierarchy of eligible dependent with new data" do
    account_group = insert(:account_group)
    [a1] = AccountHierarchyOfEligibleDependentSeeder.seed(data(account_group))
    assert a1.account_group_id == account_group.id
  end

  test "seed user with existing data" do
    account_group = insert(:account_group)
    _data = [
      %{
        ranking: 2
      }
    ]
    [a1] = AccountHierarchyOfEligibleDependentSeeder.seed(data(account_group))
    assert a1.account_group_id == account_group.id
  end

  defp data(account_group) do
    [
      %{
        hierarchy_type: "Married Employee",
        dependent: "Spouse",
        ranking: 1,
        account_group_id: account_group.id
      }
    ]
  end

end
