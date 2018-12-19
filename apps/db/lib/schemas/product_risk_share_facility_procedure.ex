defmodule Innerpeace.Db.Schemas.ProductRiskShareFacilityProcedure do
  @moduledoc false

  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :rs_type,
    :rs_value,
    :rs_covered,
    :product_risk_share_facility,
    :procedure,
    :id
  ]}

  schema "product_risk_share_facility_procedures" do

    belongs_to :product_risk_share_facility,
      Innerpeace.Db.Schemas.ProductRiskShareFacility,
      foreign_key: :product_risk_share_facility_id
    belongs_to :procedure, Innerpeace.Db.Schemas.Procedure, foreign_key: :procedure_id

    field :rs_type, :string
    field :rs_value, :string
    field :rs_covered, :integer

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :product_risk_share_facility_id,
      :procedure_id,
      :rs_type,
      :rs_value,
      :rs_covered
    ])
    |> validate_required([
      :product_risk_share_facility_id,
      :procedure_id,
      :rs_type,
      :rs_value,
      :rs_covered
    ])
  end
end
