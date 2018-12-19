defmodule Innerpeace.Db.Schemas.ProductExclusion do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :id
  ]}

  schema "product_exclusions" do

    field :start_date, Ecto.Date
    field :end_date, Ecto.Date
    belongs_to :exclusion, Innerpeace.Db.Schemas.Exclusion
    belongs_to :product, Innerpeace.Db.Schemas.Product
    has_one :product_exclusion_limit, Innerpeace.Db.Schemas.ProductExclusionLimit, on_delete: :delete_all

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:exclusion_id, :product_id])
    |> validate_required([:exclusion_id, :product_id])
  end

  def changeset_genex(struct, params \\ %{}) do
    struct
    |> cast(params, [:exclusion_id, :product_id])
    |> validate_required([:exclusion_id, :product_id])
  end

  def changeset_pre_existing(struct, params \\ %{}) do
    struct
    |> cast(params, [:exclusion_id, :product_id])
    |> validate_required([:exclusion_id, :product_id])
  end
end
