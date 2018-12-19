defmodule Innerpeace.Db.Schemas.PermissionTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Permission

  test "changeset with valid attributes" do
    params = %{
      name: "application",
      description: "description",
      status: "status",
      module: "module",
      keyword: "key",
      application_id: "388412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = Permission.changeset(%Permission{}, params)
    assert changeset.valid?
  end
end
