defmodule Innerpeace.Db.Schemas.FacilityCategory do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :type
  ]}

  schema "facility_categories" do

    field :type, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:type])
    |> validate_required([:type])
  end
end
