defmodule Innerpeace.Db.Schemas.RoleTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Role

  test "changeset with valid attributes" do
    params = %{
      name: "role",
      description: "description",
      status: "status"
    }

    changeset = Role.changeset(%Role{}, params)
    assert changeset.valid?
  end
end
