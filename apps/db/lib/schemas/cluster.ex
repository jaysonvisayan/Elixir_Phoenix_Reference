defmodule Innerpeace.Db.Schemas.Cluster do
  use Innerpeace.Db.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @derive {Poison.Encoder, only: [:code, :name]}

  @timestamps_opts [usec: false]
  schema "clusters" do
    field :code, :string
    field :name, :string
    field :step, :integer
    field :created_by, :binary_id
    field :updated_by, :binary_id

    belongs_to :industry, Innerpeace.Db.Schemas.Industry
    has_many :account_group_cluster, Innerpeace.Db.Schemas.AccountGroupCluster, on_delete: :delete_all
    has_many :cluster_log, Innerpeace.Db.Schemas.ClusterLog, on_delete: :delete_all
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :step,
      :code,
      :name,
      :created_by,
      :updated_by
    ])
    |> unique_constraint(:code, message: "Cluster Code already exist!")
    |> validate_required([
      :code,
      :name
    ])
  end

  def update_general_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name
    ])
    |> validate_required([:name])
  end

  def changeset_step(struct, params \\ %{}) do
    struct
    |> cast(params, [:step])
  end

end
