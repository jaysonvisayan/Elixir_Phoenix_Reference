defmodule Innerpeace.Db.Schemas.BenefitDiagnosis do
  use Innerpeace.Db.Schema

  schema "benefit_diagnoses" do
    field :exclusion, :string
    field :mark, :string

    belongs_to :benefit, Innerpeace.Db.Schemas.Benefit
    belongs_to :diagnosis, Innerpeace.Db.Schemas.Diagnosis

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:benefit_id, :diagnosis_id, :exclusion, :mark])
    |> validate_required([:benefit_id, :diagnosis_id])
  end
end
