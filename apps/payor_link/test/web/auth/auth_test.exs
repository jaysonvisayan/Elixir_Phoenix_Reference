defmodule Innerpeace.Db.Base.AuthTest do
  use Innerpeace.PayorLink.Web.ConnCase

  alias Innerpeace.Db.Schemas.User
  alias Innerpeace.Auth

  test "validate_username_and_password with valid params" do
    conn = build_conn()
    params = %{
      username: "abcdef",
      password: "password",
      is_admin: false
    }

    changeset = User.admin_changeset(%User{}, params)

    changeset
    |> Repo.insert

    {status, conn} = Auth.username_and_pass(conn, "abcdef", "password")

    assert status == :ok
    assert current_resource(conn).username == "abcdef"
  end

  test "validate_username_and_password with invalid params" do
    conn = build_conn()
    params = %{
      username: "abcdef",
      password: "password",
      is_admin: false
    }

    changeset = User.admin_changeset(%User{}, params)

    changeset
    |> Repo.insert

    {status, error, _conn} = Auth.username_and_pass(conn, "abcd", "password")

    assert status == :error
    assert error == :not_found
  end

  test "validate_username_and_password with empty/null_byte username" do
    conn = build_conn()
    params = %{
      username: "abcdef",
      password: "password",
      is_admin: false
    }

    changeset = User.admin_changeset(%User{}, params)

    changeset
    |> Repo.insert

    {status, error, _conn} = Auth.username_and_pass(conn, "\x00", "password")

    assert status == :error
    assert error == :invalid_username
  end

  test "validate_username_and_password with invalid username" do
    conn = build_conn()
    params = %{
      username: "abcdef",
      password: "password",
      is_admin: false
    }

    changeset = User.admin_changeset(%User{}, params)

    changeset
    |> Repo.insert

    {status, error, _conn} = Auth.username_and_pass(conn, %{"$acunetix" => "1"}, "password")

    assert status == :error
    assert error == :invalid_username
  end

  defp current_resource(conn) do
      [id, _random] =
        conn
        |> Guardian.Plug.current_resource()
        |> String.split("+")

    Repo.get(User, id)
  end

end
