defmodule Innerpeace.Db.Schemas.ClusterLog do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :inserted_at,
    :message
  ]}
  schema "cluster_logs" do
    belongs_to :cluster, Innerpeace.Db.Schemas.Cluster
    belongs_to :user, Innerpeace.Db.Schemas.User
    field :message, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :cluster_id,
      :user_id,
      :message
    ])
  end
end
