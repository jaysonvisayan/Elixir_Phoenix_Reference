defmodule Innerpeace.Db.Schemas.BenefitMiscellaneous do
  use Innerpeace.Db.Schema

  schema "benefit_miscellaneous" do
    ## clone purpose
    field :code, :string
    field :description, :string
    field :price, :decimal

    belongs_to :benefit, Innerpeace.Db.Schemas.Benefit
    belongs_to :miscellaneous, Innerpeace.Db.Schemas.Miscellaneous

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :benefit_id,
      :miscellaneous_id,
      :code,
      :description,
      :price
    ])
    |> validate_required([
      :benefit_id,
      :miscellaneous_id,
      :code,
      :description,
      :price
    ])
  end
end
