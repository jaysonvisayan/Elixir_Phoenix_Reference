defmodule Innerpeace.Db.Schemas.MemberContactTest do
  use Innerpeace.Db.SchemaCase
  # alias Innerpeace.Db.Schemas.Contact
  # alias Innerpeace.Db.Schemas.Member
  alias Innerpeace.Db.Schemas.MemberContact

  test "changeset with valud attributes" do
    member = insert(:member)
    contact = insert(:contact)
    params = %{
      contact_id: contact.id,
      member_id: member.id
    }
    changeset = MemberContact.changeset(%MemberContact{}, params)
    assert changeset.valid?
  end

  test "test changeset with invalid attributes" do
    params = %{
      contact_id: "",
      member_id: ""
    }
    changeset = MemberContact.changeset(%MemberContact{}, params)
    refute changeset.valid?
  end
end
