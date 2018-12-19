defmodule Innerpeace.Db.Schemas.EmergencyContactTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.EmergencyContact

  test "changeset with valid attributes" do
    params = %{
      member_id: Ecto.UUID.generate()
    }
    changeset = EmergencyContact.changeset(%EmergencyContact{}, params)
    assert changeset.valid?
  end

  test "test changeset with invalid attributes" do
    changeset = EmergencyContact.changeset(%EmergencyContact{})
    refute changeset.valid?
  end
end
