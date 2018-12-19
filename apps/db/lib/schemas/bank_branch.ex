defmodule Innerpeace.Db.Schemas.BankBranch do
  use Innerpeace.Db.Schema

  schema "bank_branches" do
    field :unit_no, :string
    field :bldg_name, :string
    field :street_name, :string
    field :municipality, :string
    field :province, :string
    field :region, :string
    field :country, :string
    field :postal_code, :string
    field :phone, :string
    field :branch_type, :string

    belongs_to :bank, Innerpeace.Db.Schemas.Bank
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :unit_no,
      :bldg_name,
      :street_name,
      :municipality,
      :province,
      :region,
      :country,
      :postal_code,
      :phone,
      :branch_type
    ])
    |> validate_required([:branch_type])
  end
end
