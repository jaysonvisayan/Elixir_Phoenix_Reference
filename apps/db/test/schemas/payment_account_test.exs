defmodule Innerpeace.Db.Schemas.PaymentAccountTest do
  use Innerpeace.Db.SchemaCase
  alias Ecto.UUID
  alias Innerpeace.Db.Schemas.PaymentAccount

  test "changeset with valid attributes" do
    params = %{
      bank_account: "some content",
      card_number: "some content",
      mode_of_payment: "some content",
      practitioner_id: UUID.generate(),
      bank_id: UUID.generate()
    }

    changeset = PaymentAccount.changeset(%PaymentAccount{}, params)
    assert changeset.valid?
  end

end
