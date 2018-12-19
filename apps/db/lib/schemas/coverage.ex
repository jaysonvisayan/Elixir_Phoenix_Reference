defmodule Innerpeace.Db.Schemas.Coverage do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :name
  ]}

  @timestamps_opts [usec: false]
  schema "coverages" do
    field :name, :string
    field :description, :string
    field :status, :string
    field :type, :string
    field :plan_type, :string
    field :code, :string

    #has_many :coverage_facilities, Innerpeace.Db.Schemas.CoverageFacility, on_delete: :delete_all
    has_many :coverage_benefits, Innerpeace.Db.Schemas.BenefitCoverage, on_delete: :delete_all
    #many_to_many :facilities, Innerpeace.Facility, join_through: "coverage_facilities"
    #has_many :authorizations, Innerpeace.Authorization, on_delete: :delete_all
    #has_many :eligibilities, Innerpeace.Eligibility
    has_many :authorizations, Innerpeace.Db.Schemas.Authorization
    has_many :diagnosis_coverages, Innerpeace.Db.Schemas.DiagnosisCoverage
    has_many :coverage_approval_limit_amount, Innerpeace.Db.Schemas.CoverageApprovalLimitAmount
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :description,
      :status,
      :type,
      :plan_type,
      :code
    ])
    |> validate_required([
      :name,
      :description,
      :status,
      :type,
      :code
    ])
    |> unique_constraint(:code)
  end

end
