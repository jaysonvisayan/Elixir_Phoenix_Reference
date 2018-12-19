defmodule Innerpeace.Db.Schemas.AccountProductBenefit do
  @moduledoc """
    Schema and changesets for AccountProductBenefit
  """
  use Innerpeace.Db.Schema

  schema "account_product_benefits" do
    field :limit_type, :string
    field :limit_value, :string

    belongs_to :account_product, Innerpeace.Db.Schemas.AccountProduct
    belongs_to :product_benefit, Innerpeace.Db.Schemas.ProductBenefit

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:account_product_id, :product_benefit_id])
    |> validate_required([:account_product_id, :product_benefit_id])
  end
end
