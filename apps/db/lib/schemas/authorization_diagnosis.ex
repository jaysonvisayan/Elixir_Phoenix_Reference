defmodule Innerpeace.Db.Schemas.AuthorizationDiagnosis do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "authorization_diagnosis" do
    belongs_to :authorization, Innerpeace.Db.Schemas.Authorization
    belongs_to :diagnosis, Innerpeace.Db.Schemas.Diagnosis
    belongs_to :member_product, Innerpeace.Db.Schemas.MemberProduct
    belongs_to :product_benefit, Innerpeace.Db.Schemas.ProductBenefit
    belongs_to :product_exclusion, Innerpeace.Db.Schemas.ProductExclusion
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id
    
    field :payor_pay, :decimal
    field :payor_portion, :decimal
    field :payor_vat_amount, :decimal

    field :member_pay, :decimal
    field :member_portion, :decimal
    field :member_vat_amount, :decimal

    field :special_approval_amount, :decimal
    field :special_approval_portion, :decimal
    field :special_approval_vat_amount, :decimal

    field :vat_amount, :decimal
    field :total_amount, :decimal
    field :pre_existing_amount, :decimal

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :authorization_id,
      :diagnosis_id,
      :created_by_id,
      :updated_by_id,
      :member_product_id,
      :product_benefit_id,
      :product_exclusion_id,
      :member_pay,
      :member_vat_amount,
      :member_portion,
      :payor_pay,
      :payor_vat_amount,
      :payor_portion,
      :special_approval_amount,
      :special_approval_vat_amount,
      :special_approval_portion,
      :pre_existing_amount,
      :total_amount
    ])
    |> validate_required([
      :authorization_id,
      :diagnosis_id,
      :created_by_id,
      :updated_by_id
    ])
  end
end
