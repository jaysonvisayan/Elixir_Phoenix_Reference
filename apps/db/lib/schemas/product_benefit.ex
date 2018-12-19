defmodule Innerpeace.Db.Schemas.ProductBenefit do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :benefit_id
  ]}

  schema "product_benefits" do

    field :limit_type, :string
    field :limit_value, :integer

    belongs_to :benefit, Innerpeace.Db.Schemas.Benefit
    belongs_to :product, Innerpeace.Db.Schemas.Product
    belongs_to :product_coverage, Innerpeace.Db.Schemas.ProductCoverage
    has_many :account_product_benefits, Innerpeace.Db.Schemas.AccountProductBenefit, on_delete: :delete_all

    has_many :product_benefit_limits, Innerpeace.Db.Schemas.ProductBenefitLimit, on_delete: :delete_all

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:benefit_id, :product_id, :limit_value, :limit_type])
    |> validate_required([:benefit_id, :product_id])
    |> unique_constraint(:benefit_id,  name: :product_benefits_product_id_benefit_id_index, message: "Benefit is already added!")
  end

  def update_pc_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:product_coverage_id])
    |> validate_required([:product_coverage_id])
  end
end
