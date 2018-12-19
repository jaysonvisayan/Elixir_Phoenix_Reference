defmodule Innerpeace.Db.Schemas.AuthorizationProcedureDiagnosis do
  use Innerpeace.Db.Schema

  schema "authorization_procedure_diagnoses" do
    field :unit, :decimal
    field :amount, :decimal

    field :risk_share_type, :string
    field :risk_share_setup, :string
    field :risk_share_amount, :decimal
    field :percentage_covered, :decimal
    field :pec, :decimal
    field :philhealth_pay, :decimal
    field :member_pay, :decimal
    field :payor_pay, :decimal

    belongs_to :authorization, Innerpeace.Db.Schemas.Authorization
    belongs_to :product_benefit, Innerpeace.Db.Schemas.ProductBenefit
    belongs_to :payor_procedure, Innerpeace.Db.Schemas.PayorProcedure
    belongs_to :diagnosis, Innerpeace.Db.Schemas.Diagnosis
    belongs_to :member_product, Innerpeace.Db.Schemas.MemberProduct
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id
    belongs_to :authorization_practitioner_specialization, Innerpeace.Db.Schemas.AuthorizationPractitionerSpecialization

    #For Inpatient
    belongs_to :authorization_room, Innerpeace.Db.Schemas.AuthorizationRoom

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :authorization_id,
      :payor_procedure_id,
      :diagnosis_id,
      :created_by_id,
      :updated_by_id,
      :unit,
      :amount,
      :risk_share_type,
      :risk_share_setup,
      :risk_share_amount,
      :percentage_covered,
      :pec,
      :philhealth_pay,
      :member_product_id,
      :product_benefit_id,
      :payor_pay,
      :member_pay,
      :authorization_practitioner_specialization_id
    ])
    |> validate_required([
      :authorization_id,
      :payor_procedure_id,
      :diagnosis_id,
      :updated_by_id
    ])
  end

  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :member_product_id,
      :product_benefit_id,
      :payor_pay,
      :member_pay,
      :unit,
      :amount
    ])
    |> validate_required([
      :unit,
      :amount
    ])
  end

  def diagnosis_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :authorization_id,
      :diagnosis_id,
      :created_by_id,
      :updated_by_id,
      :risk_share_type,
      :risk_share_setup,
      :risk_share_amount,
      :percentage_covered,
      :pec,
      :philhealth_pay,
      :member_product_id,
      :product_benefit_id,
      :payor_pay,
      :member_pay,
    ])
    |> validate_required([
      :authorization_id,
      :diagnosis_id,
      :updated_by_id
    ])
  end

end

