defmodule Innerpeace.Db.Schemas.BenefitCoverage do
  use Innerpeace.Db.Schema

  schema "coverage_benefits" do
    belongs_to :coverage, Innerpeace.Db.Schemas.Coverage
    belongs_to :benefit, Innerpeace.Db.Schemas.Benefit

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:coverage_id, :benefit_id])
    |> validate_required([:coverage_id, :benefit_id])
  end

end
