defmodule Innerpeace.Db.Schemas.ProductCoverageDentalRiskShare do
  @moduledoc false

  use Innerpeace.Db.Schema

  # @derive {Poison.Encoder, only: [
  #   :af_type,
  #   :af_value,
  #   :af_covered_percentage,
  #   :af_covered_amount,
  #   :naf_reimbursable,
  #   :naf_type,
  #   :naf_value,
  #   :naf_covered_percentage,
  #   :naf_covered_amount,
  #   :id
  # ]}

  schema "product_coverage_dental_risk_shares" do

    belongs_to :product_coverage, Innerpeace.Db.Schemas.ProductCoverage

    field :asdf_type, :string
    field :asdf_amount, :decimal
    field :asdf_percentage, :decimal
    field :asdf_special_handling, :string

    has_many :product_coverage_dental_risk_share_facilities,
      Innerpeace.Db.Schemas.ProductCoverageDentalRiskShareFacility,
      on_delete: :delete_all

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :product_coverage_id,
      :asdf_type,
      :asdf_amount,
      :asdf_percentage,
      :asdf_special_handling
    ])
    |> validate_required([
      :product_coverage_id
    ])
  end

end
