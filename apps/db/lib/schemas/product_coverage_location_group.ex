defmodule Innerpeace.Db.Schemas.ProductCoverageLocationGroup do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "product_coverage_location_groups" do

    belongs_to :location_group, Innerpeace.Db.Schemas.LocationGroup
    belongs_to :product_coverage, Innerpeace.Db.Schemas.ProductCoverage

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(
      params, [
        :location_group_id,
        :product_coverage_id,
      ])
      |> validate_required([
        :location_group_id,
        :product_coverage_id
      ])
  end
end
