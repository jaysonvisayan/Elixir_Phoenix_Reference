defmodule Innerpeace.Db.Schemas.ProductCoverageLimitThresholdFacility do
  use Innerpeace.Db.Schema

  schema "product_coverage_limit_threshold_facilities" do
    belongs_to :product_coverage_limit_threshold, Innerpeace.Db.Schemas.ProductCoverage
    belongs_to :facility, Innerpeace.Db.Schemas.Facility
    field :limit_threshold, :decimal
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :product_coverage_limit_threshold_id,
      :facility_id,
      :limit_threshold
    ])
    |> validate_required([
      :product_coverage_limit_threshold_id
    ])
  end

end
