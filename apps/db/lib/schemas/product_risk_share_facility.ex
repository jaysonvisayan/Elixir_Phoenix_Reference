defmodule Innerpeace.Db.Schemas.ProductRiskShareFacility do
  @moduledoc false

  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :type,
    :value,
    :covered,
    :facility,
    :product_risk_share,
    :id
  ]}

  schema "product_risk_share_facilities" do

    belongs_to :product_risk_share, Innerpeace.Db.Schemas.ProductRiskShare, foreign_key: :product_risk_share_id
    belongs_to :facility, Innerpeace.Db.Schemas.Facility, foreign_key: :facility_id

    field :type, :string
    field :value, :string
    field :covered, :integer

    has_many :product_risk_shares_facility_procedures,
      Innerpeace.Db.Schemas.ProductRiskShareFacilityProcedure,
      on_delete: :delete_all

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :product_risk_share_id,
      :facility_id,
      :type,
      :value,
      :covered
    ])
    |> validate_required([
      :product_risk_share_id,
      :facility_id,
      :type,
      :value,
      :covered
    ])
  end
end
