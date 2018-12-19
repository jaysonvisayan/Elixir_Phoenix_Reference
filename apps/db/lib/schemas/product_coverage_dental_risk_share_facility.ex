defmodule Innerpeace.Db.Schemas.ProductCoverageDentalRiskShareFacility do
  @moduledoc false

  use Innerpeace.Db.Schema

  # @derive {Poison.Encoder, only: [
  #   :type,
  #   :value,
  #   :covered,
  #   :facility,
  #   :product_coverage_risk_share,
  #   :id,
  #   :value_amount,
  #   :value_percentage
  # ]}

  schema "product_coverage_dental_risk_share_facilities" do

    belongs_to :product_coverage_dental_risk_share, Innerpeace.Db.Schemas.ProductCoverageDentalRiskShare
    belongs_to :facility, Innerpeace.Db.Schemas.Facility

    field :sdf_type, :string
    field :sdf_amount, :decimal
    field :sdf_percentage, :decimal
    field :sdf_special_handling, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :id,
      :sdf_type,
      :sdf_amount,
      :sdf_percentage,
      :sdf_special_handling
    ])
  end
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :product_coverage_dental_risk_share_id,
      :facility_id,
      :sdf_type,
      :sdf_amount,
      :sdf_percentage,
      :sdf_special_handling
    ])
    |> validate_required([
      :product_coverage_dental_risk_share_id,
      :facility_id
    ])
  end
end
