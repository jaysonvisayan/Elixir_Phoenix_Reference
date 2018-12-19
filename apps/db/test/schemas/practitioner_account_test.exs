defmodule Innerpeace.Db.Schemas.PractitionerAccountTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.PractitionerAccount

  test "changeset with valid attributes" do
    params = %{
      practitioner_id: Ecto.UUID.generate(),
      account_group_id: Ecto.UUID.generate()
    }

    changeset = PractitionerAccount.changeset(%PractitionerAccount{}, params)
    assert changeset.valid?
  end

end

