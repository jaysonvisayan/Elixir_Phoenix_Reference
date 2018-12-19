defmodule Innerpeace.Db.Schemas.EmailTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Email

  test "changeset with valid attributes" do
    params = %{
      address: "a@a.com",
      type: "email",
      contact_id: "488412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = Email.changeset(%Email{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      address: "aadasda",
      type: "email",
      contact_id: "488412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = Email.changeset(%Email{}, params)
    refute changeset.valid?
  end

  test "changeset_kyc with valid attributes" do
    params = %{
      address: "a@a.com",
      type: "email",
      kyc_bank_id: "488412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = Email.changeset_kyc(%Email{}, params)
    assert changeset.valid?
  end

end
