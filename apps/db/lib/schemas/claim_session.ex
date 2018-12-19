defmodule Innerpeace.Db.Schemas.ClaimSession do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "claim_sessions" do
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id
    belongs_to :benefit_packages, Innerpeace.Db.Schemas.BenefitPackage, foreign_key: :benefit_package_id
    belongs_to :member, Innerpeace.Db.Schemas.Member
    belongs_to :facility, Innerpeace.Db.Schemas.Facility
    belongs_to :coverages, Innerpeace.Db.Schemas.Coverage, foreign_key: :coverage_id
    belongs_to :claims, Innerpeace.Db.Schemas.Claim, foreign_key: :claim_id

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :member_id,
      :coverage_id,
      :facility_id,
      :claim_id,
      :benefit_package_id
    ])
    |> validate_required([
      :member_id,
      :coverage_id,
      :facility_id,
      :claim_id,
      :benefit_package_id
    ])
  end

  def changeset_constraints(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :coverage_id,
      :facility_id,
      :member_id
    ])
    |> validate_required([
      :coverage_id,
      :facility_id,
      :member_id
    ])
  end
end
