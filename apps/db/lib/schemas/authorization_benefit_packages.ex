defmodule Innerpeace.Db.Schemas.AuthorizationBenefitPackage do
  use Innerpeace.Db.Schema

  schema "authorization_benefit_packages" do
    belongs_to :authorization, Innerpeace.Db.Schemas.Authorization
    belongs_to :benefit_package, Innerpeace.Db.Schemas.BenefitPackage
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id
    belongs_to :member_product, Innerpeace.Db.Schemas.MemberProduct
    belongs_to :product_benefit, Innerpeace.Db.Schemas.ProductBenefit

    field :package_rate, :decimal

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :authorization_id,
      :benefit_package_id,
      :created_by_id,
      :updated_by_id,
      :package_rate,
      :member_product_id,
      :product_benefit_id
    ])
    |> validate_required([
      :authorization_id,
      :benefit_package_id,
      :created_by_id,
      :updated_by_id,
      :package_rate,
      :member_product_id,
      :product_benefit_id
    ])
  end
end
