defmodule Innerpeace.Db.Base.AuthContextTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.User
  alias Innerpeace.Db.Base.AuthContext

  test "validate_username_and_password with valid params" do
    params = %{
      username: "abcdef",
      password: "password",
      is_admin: false
    }

    changeset = User.admin_changeset(%User{}, params)

    changeset
    |> Repo.insert

    {status, user} = AuthContext.authenticate("abcdef", "password")

    assert status == :ok
    assert user.username == "abcdef"
  end

  test "validate_username_and_password with invalid params" do
    params = %{
      username: "abcdef",
      password: "password",
      is_admin: false
    }

    changeset = User.admin_changeset(%User{}, params)

    changeset
    |> Repo.insert

    {status, error} = AuthContext.authenticate("abcd", "password")

    assert status == :error
    assert error == :not_found
  end
end
