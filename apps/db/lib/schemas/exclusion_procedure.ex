defmodule Innerpeace.Db.Schemas.ExclusionProcedure do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
  ]}
  schema "exclusion_procedures" do
    belongs_to :exclusion, Innerpeace.Db.Schemas.Exclusion
    belongs_to :procedure, Innerpeace.Db.Schemas.PayorProcedure

    timestamps()
  end

  @required_fields ~w(exclusion_id procedure_id)
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:exclusion_id, :procedure_id])
    |> validate_required([:exclusion_id, :procedure_id])
    |> assoc_constraint(:exclusion)
    |> assoc_constraint(:procedure)
  end
end
