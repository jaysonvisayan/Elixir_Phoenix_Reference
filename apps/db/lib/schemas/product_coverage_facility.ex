defmodule Innerpeace.Db.Schemas.ProductCoverageFacility do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :id,
    :facility
  ]}

  schema "product_coverage_facilities" do

    belongs_to :facility, Innerpeace.Db.Schemas.Facility
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
        :facility_id,
        :product_coverage_id,
      ])
      |> validate_required([
        :facility_id,
        :product_coverage_id
      ])
  end
end
