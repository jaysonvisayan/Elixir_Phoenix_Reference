defmodule Innerpeace.Db.Schemas.Phone do
  @moduledoc false

  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [:number, :type, :country_code,
                                  :area_code, :local]}
  schema "phones" do
    field :number, :string
    field :type, :string
    field :country_code, :string
    field :area_code, :string
    field :local, :string

    belongs_to :contact, Innerpeace.Db.Schemas.Contact
    belongs_to :kyc_bank, Innerpeace.Db.Schemas.KycBank
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :contact_id,
      :number,
      :type,
      :country_code,
      :area_code,
      :local
    ])
    |> validate_length(:number, min: 7, max: 13)
    |> validate_required([:number, :contact_id, :type])
    |> assoc_constraint(:contact)
  end

  def changeset_kyc(struct, params \\ %{}) do
    struct
    |> cast(params, [:kyc_bank_id, :number, :type])
    |> validate_length(:number, min: 7, max: 13)
    |> validate_required([:number, :kyc_bank_id, :type])
    |> assoc_constraint(:kyc_bank)
  end

  def changeset_kyc_web_step2(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :number,
      :type,
      :kyc_bank_id
    ])
    |> assoc_constraint(:kyc_bank)
  end

  def changeset_sap(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :contact_id,
      :number,
      :type,
      :area_code,
      :local
    ])
  end

end
