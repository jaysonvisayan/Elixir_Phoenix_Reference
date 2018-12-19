defmodule Innerpeace.Db.Base.AuthorizationLogTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.AuthorizationLog

  test "changeset with valid params" do
    params = %{
      authorization_id: Ecto.UUID.generate(),
      user_id: Ecto.UUID.generate(),
      message: "TEST MESSAGE"
    }
    changeset = AuthorizationLog.changeset(%AuthorizationLog{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid params" do
    changeset = AuthorizationLog.changeset(%AuthorizationLog{})
    refute changeset.valid?
  end
end
