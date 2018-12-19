defmodule Innerpeace.Db.Schemas.RoleApplicationTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.RoleApplication

  test "changeset with valid attributes" do
    params = %{
      role_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      application_id: "388412e1-1668-42b7-86d2-bd57f46678b6"
    }

    changeset = RoleApplication.changeset(%RoleApplication{}, params)
    assert changeset.valid?

  end
end
