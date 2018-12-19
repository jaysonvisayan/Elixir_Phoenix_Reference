defmodule Innerpeace.Db.Schemas.Industry do
  use Innerpeace.Db.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @timestamps_opts [usec: false]
  schema "industries" do
    field :code, :string

    has_one :cluster, Innerpeace.Db.Schemas.Cluster

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:code])
    |> validate_required([:code])
  end

end
