defmodule Innerpeace.Db.Schemas.BenefitRUV do
  @moduledoc """
    Schema and changeset for Benefit RUVs
  """

  use Innerpeace.Db.Schema

  schema "benefit_ruvs" do
    belongs_to :benefit, Innerpeace.Db.Schemas.Benefit
    belongs_to :ruv, Innerpeace.Db.Schemas.RUV

    timestamps()
  end

  @required_fields ~w(benefit_id ruv_id)
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :benefit_id,
      :ruv_id
    ])
    |> validate_required([:benefit_id, :ruv_id])
    |> assoc_constraint(:benefit)
    |> assoc_constraint(:ruv)
  end
end
