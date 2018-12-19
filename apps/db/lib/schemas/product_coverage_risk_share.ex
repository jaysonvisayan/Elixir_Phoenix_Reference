defmodule Innerpeace.Db.Schemas.ProductCoverageRiskShare do
  @moduledoc false

  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :af_type,
    :af_value,
    :af_covered_percentage,
    :af_covered_amount,
    :naf_reimbursable,
    :naf_type,
    :naf_value,
    :naf_covered_percentage,
    :naf_covered_amount,
    :id
  ]}

  schema "product_coverage_risk_shares" do

    belongs_to :product_coverage, Innerpeace.Db.Schemas.ProductCoverage

    field :af_type, :string
    field :af_value, :integer
    field :af_value_percentage, :integer
    field :af_value_amount, :decimal
    field :af_covered_percentage, :integer
    field :af_covered_amount, :decimal
    field :naf_reimbursable, :string
    field :naf_type, :string
    field :naf_value, :integer
    field :naf_value_percentage, :integer
    field :naf_value_amount, :decimal
    field :naf_covered_percentage, :integer
    field :naf_covered_amount, :decimal

    has_many :product_coverage_risk_share_facilities,
      Innerpeace.Db.Schemas.ProductCoverageRiskShareFacility,
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
      :af_type,
      :af_value,
      :af_value_percentage,
      :af_value_amount,
      :af_covered_percentage,
      :af_covered_amount,
      :naf_reimbursable,
      :naf_type,
      :naf_value,
      :naf_value_percentage,
      :naf_value_amount,
      :naf_covered_percentage,
      :naf_covered_amount
    ])
    |> validate_required([
      :product_coverage_id
    ])
  end

  def changeset_update(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :product_coverage_id,
      :af_type,
      :af_value,
      :af_value_percentage,
      :af_value_amount,
      :af_covered_percentage,
      :af_covered_amount,
      :naf_reimbursable,
      :naf_type,
      :naf_value,
      :naf_value_percentage,
      :naf_value_amount,
      :naf_covered_percentage,
      :naf_covered_amount,
    ])
    |> validate_required([
      :product_coverage_id,
      :af_type,
      :af_covered_percentage,
      :af_covered_amount,
      :naf_type,
      :naf_covered_percentage,
      :naf_covered_amount
    ])
  end
end
