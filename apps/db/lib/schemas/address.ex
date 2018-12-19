defmodule Innerpeace.Db.Schemas.Address do
  use Innerpeace.Db.Schema

  schema "addresses" do
    field :street, :string
    field :district, :string
    field :postal_code, :string
    field :city, :string
    field :country, :string
    field :category, :string
    field :type, :string

    belongs_to :contact, Innerpeace.Db.Schemas.Contact
    belongs_to :kyc_bank, Innerpeace.Db.Schemas.KycBank
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:contact_id, :street, :district, :postal_code, :city, :country, :category, :type])
    |> validate_required([:contact_id, :street, :district, :postal_code, :city, :country, :category, :type])
    |> assoc_constraint(:contact)
  end

  def changeset_kyc(struct, params \\ %{}) do
    struct
    |> cast(params, [:kyc_bank_id, :street, :district, :postal_code, :city, :country])
    |> validate_required([:kyc_bank_id, :street, :district, :postal_code, :city, :country])
    |> assoc_constraint(:kyc_bank)
  end
end
