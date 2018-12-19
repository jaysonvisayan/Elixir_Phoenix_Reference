defmodule Innerpeace.Db.Schemas.ProductCoverageRiskShareFacilityPayorProcedure do
  @moduledoc false

  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :type,
    :value,
    :covered,
    :product_coverage_risk_share_facility,
    :facility_payor_procedure,
    :id,
    :value_amount,
    :value_percentage
  ]}

  schema "product_coverage_risk_share_facility_payor_procedures" do

    belongs_to :product_coverage_risk_share_facility, Innerpeace.Db.Schemas.ProductCoverageRiskShareFacility
    belongs_to :facility_payor_procedure, Innerpeace.Db.Schemas.FacilityPayorProcedure

    field :type, :string
    field :value, :string
    field :value_percentage, :integer
    field :value_amount, :decimal
    field :covered, :integer

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :product_coverage_risk_share_facility_id,
      :facility_payor_procedure_id,
      :type,
      :value,
      :value_percentage,
      :value_amount,
      :covered
    ])
    |> validate_required([
      :product_coverage_risk_share_facility_id,
      :facility_payor_procedure_id,
      :type,
      :covered
    ])
  end
end
