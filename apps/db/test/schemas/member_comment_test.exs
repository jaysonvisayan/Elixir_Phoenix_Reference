defmodule Innerpeace.Db.Schemas.MemberCommentTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.MemberComment

  test "changeset with valud attributes" do
    user = insert(:user)
    member = insert(:member)
    params = %{
      comment: "test comment",
      member_id: member.id,
      created_by_id: user.id,
      updated_by_id: user.id
    }
    changeset = MemberComment.changeset(%MemberComment{}, params)
    assert changeset.valid?
  end

end
