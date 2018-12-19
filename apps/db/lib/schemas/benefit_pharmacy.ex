defmodule Innerpeace.Db.Schemas.BenefitPharmacy do
  use Innerpeace.Db.Schema

  schema "benefit_pharmacies" do
    ## clone purpose
    field :drug_code, :string
    field :generic_name, :string
    field :brand, :string
    field :strength, :integer
    field :form, :string
    field :maximum_price, :decimal

    belongs_to :benefit, Innerpeace.Db.Schemas.Benefit
    belongs_to :pharmacy, Innerpeace.Db.Schemas.Pharmacy

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :benefit_id,
      :pharmacy_id,
      :drug_code,
      :generic_name,
      :brand,
      :strength,
      :form,
      :maximum_price
    ])
    |> validate_required([
      :benefit_id,
      :pharmacy_id,
      :drug_code,
      :generic_name,
      :brand,
      :strength,
      :form,
      :maximum_price
    ])
  end
end
