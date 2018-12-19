defmodule Innerpeace.Db.Schemas.ProductBenefitCoverage do
  use Innerpeace.Db.Schema

  schema "product_benefit_coverages" do

    belongs_to :product_benefit, Innerpeace.Db.Schemas.ProductBenefit
    belongs_to :coverage, Innerpeace.Db.Schemas.Coverage

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:product_benefit_id, :coverage_id])
    |> validate_required([:product_benefit_id, :coverage_id])
  end
end
