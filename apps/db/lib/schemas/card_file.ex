defmodule Innerpeace.Db.Schemas.CardFile do
  use Innerpeace.Db.Schema
  schema "card_files" do
    belongs_to :file, Innerpeace.Db.Schemas.File
    belongs_to :fulfillment_card, Innerpeace.Db.Schemas.FulfillmentCard
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params,[:file_id, :fulfillment_card_id])
    |> validate_required([:file_id, :fulfillment_card_id])
  end

end
