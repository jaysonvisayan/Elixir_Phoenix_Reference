defmodule Innerpeace.Db.Schemas.AddressTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Address

  test "changeset with valid attributes" do
    params = %{
      street: "test street",
      district: "test district",
      postal_code: "1600",
      city: "Pasig",
      country: "Filipinas",
      category: "test category",
      type: "test type",
      contact_id: "488412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = Address.changeset(%Address{}, params)
    assert changeset.valid?
  end

  test "changeset_kyc with valid attributes" do
    params = %{
      street: "test street",
      district: "test district",
      postal_code: "1600",
      city: "Pasig",
      country: "Filipinas",
      kyc_bank_id: "488412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = Address.changeset_kyc(%Address{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      street: "",
      district: "test district",
      postal_code: "1600",
      city: "Pasig",
      country: "Filipinas",
      category: "test category",
      type: "test type",
      contact_id: "488412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = Address.changeset(%Address{}, params)
    refute changeset.valid?
  end
end
