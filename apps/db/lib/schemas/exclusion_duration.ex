defmodule Innerpeace.Db.Schemas.ExclusionDuration do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :disease_type,
    :duration,
    :percentage
  ]}

  schema "exclusion_durations" do
    belongs_to :exclusion, Innerpeace.Db.Schemas.Exclusion
    field :disease_type, :string
    field :duration, :integer
    field :percentage, :integer
    timestamps()
    ## newly added fields
    field :covered_after_duration, :string ## Peso || Percentage
    field :cad_percentage, :integer
    field :cad_amount, :decimal
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :exclusion_id,
      :disease_type,
      :duration,
      :percentage,
      :covered_after_duration,
      :cad_percentage,
      :cad_amount
    ])
    |> validate_required([
      :exclusion_id,
      :duration,
      :disease_type
    ])
  end
end
