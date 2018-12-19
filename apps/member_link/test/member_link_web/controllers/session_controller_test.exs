defmodule MemberLinkWeb.SessionControllerTest do
  use MemberLinkWeb.ConnCase
  # use Innerpeace.Db.SchemaCase, async: true

  alias Innerpeace.Db.Base.{
    UserContext
  }

  setup do
    member = insert(:member, status: "Active", type: "Principal")
    {:ok, user} = UserContext.register_member(member, %{
      "username" => "test_user",
      "password" => "P@ssw0rd",
      "password_confirmation" => "P@ssw0rd",
      "email" => "test@email.com",
      "mobile" => "09101010101",
      "first_name" => "test",
      "last_name" => "test",
      "gender" => "male",
      "is_admin" => "false",
      "member_id" => member.id
    })

    conn = build_conn()
           |> authenticated(user)

    {:ok, %{conn: conn, user: user}}
  end

  test "GET /sign_in", %{conn: conn} do
    conn = get conn, "/#{@locale}/sign_in"
    assert html_response(conn, 200) =~ "Login"
  end

  test "login with valid params", %{conn: conn} do
    user = UserContext.get_username("test_user")
    UserContext.update_verification(user, %{verification: true})
    conn = post conn, "#{@locale}/sign_in", session: %{
      username: "test_user",
      password: "P@ssw0rd"
    }

    assert redirected_to(conn) == "/#{@locale}"
  end

  test "login with invalid params", %{conn: conn} do
    conn = post conn, "/#{@locale}/sign_in", session: %{
      username: "test_user",
      password: "password"
    }

    assert html_response(conn, 200) =~ "username"
  end

  test "logout", %{conn: conn} do
    conn = post conn, "/#{@locale}/sign_in", session: %{
      username: "test_user",
      password: "P@ssw0rd"
    }
    conn = delete conn, "/#{@locale}/sign_out"

    assert redirected_to(conn) =~ "/#{@locale}/sign_in"
  end
end
