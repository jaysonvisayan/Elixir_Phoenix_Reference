defmodule Innerpeace.Db.Schemas.PhoneTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Phone

  test "changeset with valid attributes" do
    params = %{
      number: "09090999099",
      type: "phone",
      contact_id: "488412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = Phone.changeset(%Phone{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      number: "",
      type: "phone",
      contact_id: "488412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = Phone.changeset(%Phone{}, params)
    refute changeset.valid?
  end

  test "changeset_kyc with valid attributes" do
    params = %{
      number: "09090999099",
      type: "phone",
      kyc_bank_id: "488412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = Phone.changeset_kyc(%Phone{}, params)
    assert changeset.valid?
  end

end
