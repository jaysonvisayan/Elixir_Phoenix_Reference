defmodule AccountLinkWeb.SessionControllerTest do
  use AccountLinkWeb.ConnCase
  use Innerpeace.Db.SchemaCase, async: true

  alias Innerpeace.Db.Base.{
    UserContext,
    AccountGroupContext,
    IndustryContext
  }

  setup do
    conn = build_conn() |> assign(:locale, "en")
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
    {:ok, industry} = IndustryContext.create_industry(%{code: "sample-code"})
    params =%{
      name: "ACU123",
      type: "type",
      segment: "sample",
      industry_id: industry.id,
      original_effective_date: Ecto.Date.utc()
    }
    {:ok, account_group} = AccountGroupContext.create_an_account_group(params)
    user = UserContext.create_user_account(%{
      "user_id" => user.id,
      "acount_group_id" => account_group.id,
      "role" => "test role"
    })

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
      password: "P@ssw0rd",
      captcha: "generated_captcha_code"
    }

    assert redirected_to(conn) == "/#{@locale}/members"
  end

  test "login with invalid params", %{conn: conn} do
    conn = post conn, "/#{@locale}/sign_in", session: %{
      username: "test_user",
      password: "password",
      captcha: "generated_captcha_code"
    }

    assert html_response(conn, 200) =~ "Username"
    assert html_response(conn, 200) =~ "Password"
  end

  test "logout", %{conn: conn} do
   conn = post conn, "/#{@locale}/sign_in", session: %{
     username: "test_user",
     password: "P@ssw0rd",
     captcha: ""
    }
    conn = delete conn, "/#{@locale}/sign_out"
    assert redirected_to(conn) =~ "/#{@locale}"
  end
end
