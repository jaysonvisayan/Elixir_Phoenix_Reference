defmodule Innerpeace.Db.Schemas.RolePermissionTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.RolePermission

  test "changeset with valid attributes" do
    params = %{
      role_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      permission_id: "388412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = RolePermission.changeset(%RolePermission{}, params)
    assert changeset.valid?
  end
end
