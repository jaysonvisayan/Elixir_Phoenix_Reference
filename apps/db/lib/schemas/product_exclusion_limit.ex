defmodule Innerpeace.Db.Schemas.ProductExclusionLimit do
  use Innerpeace.Db.Schema

  @moduledoc false

  schema "product_exclusion_limits" do

    belongs_to :product_exclusion, Innerpeace.Db.Schemas.ProductExclusion

    field :limit_type, :string
    field :limit_percentage, :integer
    field :limit_peso, :decimal
    field :limit_session, :integer

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :product_exclusion_id
    ])
    |> validate_required([
      :product_exclusion_id
    ])
  end

  def changeset_pec_limit(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :product_exclusion_id,
      :limit_type,
      :limit_percentage,
      :limit_peso,
      :limit_session
    ])
    |> validate_required([
      :limit_type
    ])
    |> validate_inclusion(:limit_type, [
      "Peso",
      "Percentage",
      "Sessions"
    ])
  end

end
