defmodule Innerpeace.Db.Schemas.Pharmacy do
  use Innerpeace.Db.Schema

  schema "pharmacies" do
    field :drug_code, :string
    field :generic_name, :string
    field :brand, :string
    field :strength, :integer
    field :form, :string
    field :maximum_price, :decimal

    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id

    timestamps()
  end

  def changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [
      :drug_code,
      :generic_name,
      :brand,
      :strength,
      :form,
      :maximum_price,
      :created_by_id,
      :updated_by_id
    ])
    |> validate_required([
      :drug_code,
      :generic_name,
      :brand,
      :strength,
      :form,
      :maximum_price,
      :created_by_id,
      :updated_by_id
    ])
    |> unique_constraint(:drug_code)
  end
end
