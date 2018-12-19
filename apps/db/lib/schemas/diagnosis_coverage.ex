defmodule Innerpeace.Db.Schemas.DiagnosisCoverage do
  use Innerpeace.Db.Schema

  schema "diagnosis_coverages" do
    belongs_to :coverage, Innerpeace.Db.Schemas.Coverage
    belongs_to :diagnosis, Innerpeace.Db.Schemas.Diagnosis

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:coverage_id, :diagnosis_id])
    |> validate_required([:coverage_id, :diagnosis_id])
  end
end
