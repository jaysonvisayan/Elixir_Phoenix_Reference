defmodule Innerpeace.Db.Schemas.PemeMember do
  @moduledoc """
  """

  use Innerpeace.Db.Schema

  schema "peme_members" do
    field :evoucher_number, :string
    field :evoucher_qrcode, :string
    field :status, :string
    field :approved_datetime, Ecto.DateTime
    belongs_to :peme, Innerpeace.Db.Schemas.Peme
    belongs_to :member, Innerpeace.Db.Schemas.Member
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :evoucher_number,
      :evoucher_qrcode,
      :peme_id,
      :member_id,
      :status
    ])
    |> validate_required([
      :evoucher_number,
      :evoucher_qrcode,
      :peme_id,
      :member_id
    ])
  end

 end
