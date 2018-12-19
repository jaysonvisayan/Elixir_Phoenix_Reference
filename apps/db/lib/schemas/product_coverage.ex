defmodule Innerpeace.Db.Schemas.ProductCoverage do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "product_coverages" do

    field :type, :string
    field :funding_arrangement, :string

    belongs_to :coverage, Innerpeace.Db.Schemas.Coverage
    belongs_to :product, Innerpeace.Db.Schemas.Product
    # belongs_to :product_benefits, Innerpeace.Db.Schemas.ProductBenefit, foreign_key: :acu_product_benefit_id

    has_many :product_coverage_facilities, Innerpeace.Db.Schemas.ProductCoverageFacility, on_delete: :delete_all
    has_many :product_benefits, Innerpeace.Db.Schemas.ProductBenefit, on_delete: :delete_all

    has_one :product_coverage_room_and_board, Innerpeace.Db.Schemas.ProductCoverageRoomAndBoard, on_delete: :delete_all
    has_one :product_coverage_risk_share, Innerpeace.Db.Schemas.ProductCoverageRiskShare, on_delete: :delete_all
    has_one :product_coverage_limit_threshold,
      Innerpeace.Db.Schemas.ProductCoverageLimitThreshold,
      on_delete: :delete_all

    # for Dental Plan
    has_many :product_coverage_location_groups, Innerpeace.Db.Schemas.ProductCoverageLocationGroup, on_delete: :delete_all
    has_one :product_coverage_dental_risk_share, Innerpeace.Db.Schemas.ProductCoverageDentalRiskShare, on_delete: :delete_all

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :coverage_id,
      :product_id,
      # :acu_product_benefit_id,
      :type,
      :funding_arrangement
    ])
    |> validate_required([
      :product_id,
      :coverage_id
    ])
  end

  def changeset_funding(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :funding_arrangement
    ])
    |> validate_required([
      :funding_arrangement
    ])
  end

  def changeset_acu_product_benefit(struct, params \\ %{}) do
    struct
    |> cast(params, [
      # :acu_product_benefit_id
    ])
    |> validate_required([
      # :acu_product_benefit_id
    ])
  end

  def changeset_dental_update(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :coverage_id,
      :product_id,
      :type,
      :funding_arrangement
    ])
  end


end
