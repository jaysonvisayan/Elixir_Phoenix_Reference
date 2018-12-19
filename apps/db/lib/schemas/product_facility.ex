defmodule Innerpeace.Db.Schemas.ProductFacility do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :id,
    :is_included,
    :facility
  ]}

  schema "product_facilities" do

    field :is_included, :boolean
    field :coverage_id, :string

    belongs_to :facility, Innerpeace.Db.Schemas.Facility
    belongs_to :product, Innerpeace.Db.Schemas.Product

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:facility_id, :product_id, :is_included, :coverage_id])
    |> validate_required([:product_id, :is_included, :coverage_id])
  end
end
