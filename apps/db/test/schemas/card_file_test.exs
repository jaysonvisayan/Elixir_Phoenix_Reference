defmodule Innerpeace.Db.Schemas.CardFileTest do
  use Innerpeace.Db.SchemaCase
  # alias Innerpeace.Db.Schemas.File
  # alias Innerpeace.Db.Schemas.FulfillmentCard
  alias Innerpeace.Db.Schemas.CardFile

  test "changeset with valud attributes" do
    card = insert(:fulfillment_card)
    file = insert(:file)
    params = %{
      file_id: file.id,
      fulfillment_card_id: card.id
    }
    changeset = CardFile.changeset(%CardFile{}, params)
    assert changeset.valid?
  end

  test "test changeset with invalid attributes" do
    params = %{
      file_id: "",
      fulillment_card_id: ""
    }
    changeset = CardFile.changeset(%CardFile{}, params)
    refute changeset.valid?
  end
end
