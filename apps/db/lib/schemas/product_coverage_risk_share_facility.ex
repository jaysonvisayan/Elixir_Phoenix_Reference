defmodule Innerpeace.Db.Schemas.ProductCoverageRiskShareFacility do
  @moduledoc false

  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :type,
    :value,
    :covered,
    :facility,
    :product_coverage_risk_share,
    :id,
    :value_amount,
    :value_percentage
  ]}

  schema "product_coverage_risk_share_facilities" do

    belongs_to :product_coverage_risk_share, Innerpeace.Db.Schemas.ProductCoverageRiskShare
    belongs_to :facility, Innerpeace.Db.Schemas.Facility

    field :type, :string
    field :value, :string
    field :value_percentage, :integer
    field :value_amount, :decimal
    field :covered, :integer

    has_many :product_coverage_risk_share_facility_payor_procedures,
      Innerpeace.Db.Schemas.ProductCoverageRiskShareFacilityPayorProcedure

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :product_coverage_risk_share_id,
      :facility_id,
      :type,
      :value,
      :value_percentage,
      :value_amount,
      :covered
    ])
    |> validate_required([
      :product_coverage_risk_share_id,
      :facility_id,
      :type,
      :covered
    ])
  end
end
