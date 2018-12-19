defmodule Innerpeace.Db.Schemas.PayorCardBin do
  @moduledoc """
  """

  use Innerpeace.Db.Schema

  schema "payor_card_bins" do
    field :card_bin, :string
    field :sequence, :integer

    belongs_to :payor, Innerpeace.Db.Schemas.Payor

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :card_bin,
      :sequence,
      :payor_id
    ])
    |> validate_required([
      :card_bin,
      :sequence,
      :payor_id
    ])
  end
end
