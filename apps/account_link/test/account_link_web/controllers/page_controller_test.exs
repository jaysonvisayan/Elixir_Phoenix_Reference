defmodule AccountLinkWeb.PageControllerTest do
  use AccountLinkWeb.ConnCase
  use Innerpeace.Db.SchemaCase, async: true

  alias AccountLink.Guardian.Plug
  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    User
  }

  alias Innerpeace.Db.Base.{
    UserContext,
    AccountGroupContext,
    IndustryContext
  }

  setup do
    {:ok, user} = UserContext.create_user_accountlink(%{
      "username" => "test_user",
      "password" => "P@ssw0rd",
      "confirm_password" => "P@ssw0rd",
      "email" => "test@email.com",
      "mobile" => "09101010101",
      "first_name" => "test",
      "last_name" => "test",
      "gender" => "male",
      "is_admin" => "false"
    })

    conn = AccountLinkWeb.Auth.login(build_conn(), user)

    {:ok, %{conn: conn, user: user}}
  end

  test "GET /", %{conn: conn} do
    conn = get(conn, "/en")
    assert redirected_to(conn) == member_path(conn, :index, "en")
  end
end
