defmodule Innerpeace.Db.Schemas.AccountGroupClusterTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.AccountGroupCluster

  test "changeset with valid attributes" do
    account_group = insert(:account_group)
    cluster = insert(:cluster)
    params = %{
      account_group_id: account_group.id,
      cluster_id: cluster.id
    }

    changeset = AccountGroupCluster.changeset(%AccountGroupCluster{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{}
    changeset = AccountGroupCluster.changeset(%AccountGroupCluster{}, params)

    refute changeset.valid?
  end
end
