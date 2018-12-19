defmodule Innerpeace.Db.Schemas.ProductBenefitLimit do
  use Innerpeace.Db.Schema

  @moduledoc """
  ProductBenefitLimit Schema and Changeset
  The Purpose if this table is for CLoning of
  Benefit Limit's Data and store it here with
  product_benefit_id
  """

  @derive {Poison.Encoder, only: [
    :coverages,
    :limit_type,
    :limit_amount,
    :limit_percentage,
    :limit_session,
    :limit_tooth,
    :limit_quadrant,
    :limit_classification,
    :id
  ]}

  schema "product_benefit_limits" do

    belongs_to :product_benefit, Innerpeace.Db.Schemas.ProductBenefit
    belongs_to :benefit_limit, Innerpeace.Db.Schemas.BenefitLimit

    field :coverages, :string
    field :limit_type, :string

    field :limit_percentage, :integer
    field :limit_amount, :decimal
    field :limit_session, :integer
    field :limit_tooth, :integer
    field :limit_quadrant, :integer
    field :limit_classification, :string
    field :limit_area_type, {:array, :string}
    field :limit_area, {:array, :string}

    field :created_by_id, :binary_id
    field :updated_by_id, :binary_id

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :product_benefit_id,
      :benefit_limit_id,
      :coverages,
      :limit_type,
      :limit_percentage,
      :limit_amount,
      :limit_session,
      :limit_classification,
      :created_by_id,
      :updated_by_id,
      :limit_tooth,
      :limit_quadrant,
      :limit_area,
      :limit_area_type
    ])
    |> validate_required([
      :product_benefit_id,
      # :benefit_limit_id,
      :coverages,
      :limit_type
    ])
    |> validate_inclusion(:limit_type, ["Plan Limit Percentage", "Peso", "Session", "Tooth", "Quadrant", "Area"])
  end

  def changeset_update_product_limit(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :limit_amount,
      :limit_classification
      ])
    |> validate_required([:limit_amount])
  end
end
