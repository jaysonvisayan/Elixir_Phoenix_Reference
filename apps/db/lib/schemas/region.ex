defmodule Innerpeace.Db.Schemas.Region do
  @moduledoc """
    Schema and changesets for Region
  """
  use Innerpeace.Db.Schema

  schema "regions" do
    field :island_group, :string
    field :region, :string
    field :index, :integer

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :island_group,
      :region,
      :index
    ])
    |> validate_required([
      :island_group,
      :region
    ])
  end
end
