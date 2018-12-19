defmodule Innerpeace.Db.Schemas.UserRoleTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.UserRole

  test "changeset with valid attributes" do
    params = %{
      role_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      permission_id: "388412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = UserRole.changeset(%UserRole{}, params)
    assert changeset.valid?
  end
end
