defmodule Innerpeace.Db.Schemas.Email do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [:address, :type]}
  schema "emails" do
    field :address, :string
    field :type, :string

    belongs_to :contact, Innerpeace.Db.Schemas.Contact
    belongs_to :kyc_bank, Innerpeace.Db.Schemas.KycBank
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:contact_id, :address, :type])
    |> validate_format(:address, ~r/@/)
    |> validate_required([:contact_id, :address])
    |> assoc_constraint(:contact)
  end

  def changeset_kyc(struct, params \\ %{}) do
    struct
    |> cast(params, [:kyc_bank_id, :address, :type])
    |> validate_format(:address, ~r/@/)
    |> validate_required([:address, :kyc_bank_id, :type])
    |> assoc_constraint(:kyc_bank)
  end

  def changeset_kyc_web_step2(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :kyc_bank_id,
      :address
    ])
    |> validate_required([
      :kyc_bank_id,
      :address
    ])
    |> assoc_constraint(:kyc_bank)
  end

end
