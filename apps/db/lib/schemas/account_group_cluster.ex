defmodule Innerpeace.Db.Schemas.AccountGroupCluster do
  use Innerpeace.Db.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @timestamps_opts [usec: false]
  schema "account_clusters" do
    belongs_to :account_group, Innerpeace.Db.Schemas.AccountGroup
    belongs_to :cluster, Innerpeace.Db.Schemas.Cluster
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :account_group_id,
      :cluster_id
    ])
    |> validate_required([
      :account_group_id,
      :cluster_id
    ])
  end

end
