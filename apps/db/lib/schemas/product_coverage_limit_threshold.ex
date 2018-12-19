defmodule Innerpeace.Db.Schemas.ProductCoverageLimitThreshold do
  use Innerpeace.Db.Schema

  schema "product_coverage_limit_thresholds" do
    belongs_to :product_coverage, Innerpeace.Db.Schemas.ProductCoverage
    field :limit_threshold, :decimal

    has_many :product_coverage_limit_threshold_facilities, Innerpeace.Db.Schemas.ProductCoverageLimitThresholdFacility
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :product_coverage_id,
      :limit_threshold
    ])
    |> validate_required([
      :product_coverage_id
    ])
  end

end
