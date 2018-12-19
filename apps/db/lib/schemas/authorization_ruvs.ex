defmodule Innerpeace.Db.Schemas.AuthorizationRUV do
  use Innerpeace.Db.Schema

  schema "authorization_ruvs" do

    field :risk_share_type, :string
    field :risk_share_setup, :string
    field :risk_share_amount, :decimal
    field :percentage_covered, :decimal
    field :pec, :decimal
    field :philhealth_pay, :decimal
    field :member_pay, :decimal
    field :payor_pay, :decimal

    belongs_to :authorization, Innerpeace.Db.Schemas.Authorization
    belongs_to :facility_ruv, Innerpeace.Db.Schemas.FacilityRUV
    belongs_to :member_product, Innerpeace.Db.Schemas.MemberProduct
    belongs_to :product_benefit, Innerpeace.Db.Schemas.ProductBenefit
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :authorization_id,
      :created_by_id,
      :updated_by_id,
      :member_product_id,
      :product_benefit_id,
      :payor_pay,
      :member_pay,
      :facility_ruv_id,
      :risk_share_type,
      :risk_share_setup,
      :risk_share_amount,
      :percentage_covered,
      :pec,
      :philhealth_pay
    ])
    |> validate_required([
      :authorization_id,
      :facility_ruv_id,
      :created_by_id,
      :updated_by_id,
    ])
  end
end
