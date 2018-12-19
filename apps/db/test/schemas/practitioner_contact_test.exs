defmodule Innerpeace.Db.Schemas.PractitionerContactTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.PractitionerContact

  test "changeset with valid attributes" do
    params = %{
      type: "test",
      practitioner_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      contact_id: "488412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = PractitionerContact.changeset(%PractitionerContact{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      type: "test",
      practitioner_id: "",
      contact_id: "488412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = PractitionerContact.changeset(%PractitionerContact{}, params)
    refute changeset.valid?
  end

end
