defmodule Innerpeace.Db.Schemas.ExclusionDisease do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :disease
  ]}
  schema "exclusion_diseases" do
    belongs_to :exclusion, Innerpeace.Db.Schemas.Exclusion
    belongs_to :disease, Innerpeace.Db.Schemas.Diagnosis

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:exclusion_id, :disease_id])
    |> validate_required([:exclusion_id, :disease_id])
  end
end
