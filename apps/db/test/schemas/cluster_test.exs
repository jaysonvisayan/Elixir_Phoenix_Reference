defmodule Innerpeace.Db.Schemas.ClusterTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Cluster

  test "changeset with valid attributes" do
    industry = insert(:industry)
    params = %{
      code: "CODE1",
      name: "CLUSTER1",
      industry_id: industry.id
    }

    changeset = Cluster.changeset(%Cluster{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      name: "A"
    }
    changeset = Cluster.changeset(%Cluster{}, params)

    refute changeset.valid?
  end
end
