defmodule Innerpeace.PayorLink.Web.SessionControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  use Innerpeace.Db.PayorRepo, :context
  alias Innerpeace.Db.Schemas.User
  alias Innerpeace.Db.Repo
  # import Innerpeace.PayorLink.TestHelper
  # use Innerpeace.Db.SchemaCase

  setup do
    conn = build_conn()
    user = fixture(:user_permission, %{keyword: "manage_roles", module: "Roles"})
           |> Repo.preload([user_roles: [role:
                                         [[role_permissions: :permission],
                                          [role_applications: :application]
                                         ]]])
    conn = authenticated(conn, user)
    insert(:application, name: "test")
    user_roles = user.user_roles
    roles = Enum.map(user_roles, fn(x) ->
      x.role
    end)
    role = roles
           |> List.first()
    Enum.map(role.role_permissions, fn(x) ->
      x.permission
    end) |> List.first()

    {:ok, %{user: user, conn: conn}}
  end

  test "GET /sign_in", %{conn: conn} do
    conn = get conn, "/sign_in"
    assert html_response(conn, 200) =~ "Login"
  end

  test "renders forgot password", %{conn: conn} do
    conn = get conn, "/forgot_password"
    assert html_response(conn, 200) =~ "Forgot Password"
  end

  test "renders verification code page for email", %{conn: conn} do
    user = insert(:user, username: "test")
    conn = get conn, session_path(conn, :verify_code, user)
    assert html_response(conn, 200) =~ "Forgot Password"
  end

  test "renders verification code page for sms", %{conn: conn} do
    user = insert(:user, username: "test", mobile: "09277435476")
    conn = get conn, session_path(conn, :verify_code_sms, user)
    assert html_response(conn, 200) =~ "Verification"
  end

  test "renders resend code page", %{conn: conn} do
    user = insert(:user, username: "test", mobile: "09277435476", verification_code: "123456", gender: "male", middle_name: "asd")
    conn = get conn, session_path(conn, :resend_code, user)
    assert html_response(conn, 200) =~ "Verification"
  end

  test "renders reset password page", %{conn: conn} do
    user = insert(:user, username: "test", mobile: "09277435476", verification_code: "123456", gender: "male", middle_name: "asd", reset_token: Ecto.UUID.generate())
    conn = get conn, session_path(conn, :reset_password, user.reset_token)
    assert html_response(conn, 200) =~ "Reset Password"
  end

  test "send instruction link to email with no existing email address", %{conn: conn} do
    test1 = %{
      "userinfo" => "asdhdasd@gmail.com"
    }
    insert(:user, username: "test", email: "test@gmail.com", mobile: "09277435476", hashed_password: "test")
    conn = post conn, session_path(conn, :send_verification2), session: test1

    assert html_response(conn, 200) =~ "Forgot Password?"

    # assert redirected_to(conn) == session_path(conn, :verify_code, user.id)
  end

  # test "send instruction link to email with existing email address", %{conn: conn} do
  #   test1 = %{
  #     "userinfo" => "mediadmin@medi.com"
  #   }
  #   login_ip_address = insert(:login_ip_address, ip_address: "10.0.2.15")
  #   user = insert(:user, username: "test", email: "mediadmin@medi.com", mobile: "09277435476", hashed_password: "test")

  #   conn = post conn, session_path(conn, :send_verification2), session: test1

  #   assert html_response(conn, 200) =~ "Log in to PayorLink"

  # end


  # test "renders reset password page", %{conn: conn} do
  #   user = insert(:user, username: "test", mobile: "09277435476", verification_code: "123456", gender: "male", middle_name: "asd", reset_token: Ecto.UUID.generate())
  #   conn = get conn, session_path(conn, :reset_password, user.reset_token)
  #   assert html_response(conn, 200) =~ "Reset Password"
  # end

#   test "send link to email", %{conn: conn} do
#     test1 = %{
#       "type" => "email@medi.com",
#     }
#        conn = post conn, session_path(conn, :send_verification2), session: test1

#     assert render(conn, "forgot.password.html", user.id)
#   end


# test "sends verification code to sms", %{conn: conn} do
#   test1 = %{
#     "username" => "test",
#     "channel" => "SMS"
#   }
#   user = insert(:user, username: "test", email: "test@gmail.com", mobile: "09277435476", hashed_password: "test")
#   conn = post conn, session_path(conn, :send_verification), session: test1

#   assert redirected_to(conn) == session_path(conn, :verify_code_sms, user.id)
# end

  test "does not send verification code", %{conn: conn} do
    test1 = %{
      "userinfo" => "09172626262",
    }
    conn = post conn, session_path(conn, :send_verification2), session: test1

    assert html_response(conn, 200) =~ "Forgot Password?"

  end

  # test "does not send verification code is username is empty/null_byte", %{conn: conn} do
  #   test1 = %{
  #     "username" => "\x00",
  #     "channel" => ""
  #   }
  #   conn = post conn, session_path(conn, :send_verification), session: test1

  #   assert redirected_to(conn) == session_path(conn, :forgot_password)
  # end

  test "code is verified based on input ", %{conn: conn} do
    user = insert(:user, verification_code: "123456", mobile: "09277435476", verification_expiry: Ecto.DateTime.from_erl(:erlang.localtime))
    params = %{"verification_code" => ["1", "2", "3", "4", "5", "6"]}
    conn = post conn, session_path(conn, :code_verification, user), user: params
    user = Innerpeace.Db.Base.UserContext.get_user(user.id)
    assert redirected_to(conn) == session_path(conn, :reset_password, user.reset_token)
  end

  test "renders page if the code is not equal to user's verification code", %{conn: conn} do
    user = insert(:user, verification_code: "123455", mobile: "09277435476")
    params = %{"verification_code" => ["1", "2", "3", "4", "5", "6"]}
    conn = post conn, session_path(conn, :code_verification, user), user: params
    assert redirected_to(conn) == session_path(conn, :verify_code_sms, user)
  end

# test "resends verification code", %{conn: conn} do
#   user = insert(:user, mobile: "09277435476", hashed_password: "test")
#   params = %{
#     "channel" => "Email",
#     "username" => user.username
#   }
#   conn = put conn, session_path(conn, :update_code, user), user: params
#   assert redirected_to(conn) == session_path(conn, :verify_code, user.id)
# end

  test "successfully resets password", %{conn: conn} do
    params = %{
      "password" => "P@ssw0rd99",
      "password_confirmation" => "P@ssw0rd99"
    }
    changeset = User.password_changeset(%User{}, params)
    user = insert(:user, mobile: "09277435476", hashed_password: changeset.changes.hashed_password, reset_token: Ecto.UUID.generate())
    conn = put conn, session_path(conn, :update_password, user.reset_token), user: %{"password" => "P@ssw0rd", "password_confirmation" => "P@ssw0rd"}
    assert redirected_to(conn) == session_path(conn, :new)
  end

  test "does not update when new password is equal to old password", %{conn: conn} do
    params = %{
      "password" => "P@ssw0rd99",
      "password_confirmation" => "P@ssw0rd99"
    }
    changeset = User.password_changeset(%User{}, params)
    user = insert(:user, mobile: "09277435476", hashed_password: changeset.changes.hashed_password, reset_token: Ecto.UUID.generate())
    conn = put conn, session_path(conn, :update_password, user.reset_token), user: %{"password" => "P@ssw0rd99", "password_confirmation" => "P@ssw0rd"}
    assert html_response(conn, 200) =~ "Reset Password"
    assert conn.assigns.error == "You have used that password before, enter new one"
    # assert conn.private[:phoenix_flash]["error"] == "Cannot use old password, enter new one"
  end

  # test "does not update when password and password confirmation are not equal", %{conn: conn} do
  #   params = %{
  #     "password" => "P@ssw0rd99",
  #     "password_confirmation" => "P@ssw0rd99"
  #   }
  #   changeset = User.password_changeset(%User{}, params)
  #   user = insert(:user, mobile: "09277435476", hashed_password: changeset.changes.hashed_password, reset_token: Ecto.UUID.generate())
  #   conn = put conn, session_path(conn, :update_password, user.reset_token), user: %{"password" => "P@ssw0rd9988", "password_confirmation" => "P@ssw0rd"}
  #   assert html_response(conn, 200) =~ "Reset Password"
  #   assert conn.assigns.error == "Password and Password Confirmation doesn't match!"

  # end

  # test "does not update when password is invalid", %{conn: conn} do
  #   params = %{
  #     "password" => "P@ssw0rd99",
  #     "password_confirmation" => "P@ssw0rd99"
  #   }
  #   changeset = User.password_changeset(%User{}, params)
  #   user = insert(:user, mobile: "09277435476", hashed_password: changeset.changes.hashed_password, reset_token: Ecto.UUID.generate())
  #   conn = put conn, session_path(conn, :update_password, user.reset_token), user: %{"password" => "P@ss", "password_confirmation" => "P@ss"}
  #   assert html_response(conn, 200) =~ "Reset Password"
  #   assert conn.private[:phoenix_flash]["error"] == "Password must be at least 8 characters long and must contain at least one lower case character, one upper case character, and one special character(!@#$)"
  # end

  describe "Login User" do
    test "with right credentials and redirect when valid", %{conn: conn} do
      Innerpeace.Db.Base.UserContext.create_admin(%{
        username: "admin",
        password: "p@ssw0rd",
        payroll_code: "1",
        is_admin: true,
        first_time: false
      })
      conn = post conn, session_path(conn, :create), session: %{
        username: "admin",
        password: "p@ssw0rd",
        payroll_code: "1",
        captcha: "generated_captcha_code"
      }
      assert redirected_to(conn) == "/sign_in"
    end

    test "with invalid username", %{conn: conn} do
      Innerpeace.Db.Base.UserContext.create_admin(%{
        username: "admin",
        password: "p@ssw0rd",
        payroll_code: "1",
        is_admin: true,
        first_time: false
      })
      conn = post conn, session_path(conn, :create), session: %{
        username: "admin1",
        password: "p@ssw0rd",
        payroll_code: "1",
        captcha: "generated_captcha_code"
      }
      assert redirected_to(conn) == session_path(conn, :new)
      assert conn.private[:phoenix_flash]["error"] == "You have entered an invalid Payroll code, username or password. Try again."
    end

    test "with invalid password", %{conn: conn} do
      Innerpeace.Db.Base.UserContext.create_admin(%{
        username: "admin",
        password: "p@ssw0rd",
        payroll_code: "1",
        is_admin: true,
        first_time: false
      })
      conn = post conn, session_path(conn, :create), session: %{
        username: "admin",
        password: "p@ssw0rd1",
        payroll_code: "1",
        captcha: "generated_captcha_code"
      }
      assert redirected_to(conn) == session_path(conn, :new)
      assert conn.private[:phoenix_flash]["error"] == "You have entered an invalid Payroll code, username or password. Try again."
    end

    test "with invalid payroll code", %{conn: conn} do
      Innerpeace.Db.Base.UserContext.create_admin(%{
        username: "admin",
        password: "p@ssw0rd",
        payroll_code: "1",
        is_admin: true,
        first_time: false
      })
      conn = post conn, session_path(conn, :create), session: %{
        username: "admin",
        password: "p@ssw0rd",
        payroll_code: "2",
        captcha: "generated_captcha_code"
      }
      assert redirected_to(conn) == session_path(conn, :new)
      assert conn.private[:phoenix_flash]["error"] == "You have entered an invalid Payroll code, username or password. Try again."
    end

    test "with no captcha", %{conn: conn} do
      Innerpeace.Db.Base.UserContext.create_admin(%{
        username: "admin",
        password: "p@ssw0rd",
        payroll_code: "1",
        is_admin: true,
        first_time: false
      })
      ip = Innerpeace.Db.Base.Api.UtilityContext.get_ip(conn)
      ip_address = insert(:login_ip_address, ip_address: ip)
      Innerpeace.Db.Base.LoginIpAddressContext.update_ip_address(ip_address, %{attempts: 3})
      conn = post conn, session_path(conn, :create), session: %{
        username: "admin",
        password: "p@ssw0rd",
        payroll_code: "1",
        captcha: ""
      }
      assert redirected_to(conn) == session_path(conn, :new)
      assert conn.private[:phoenix_flash]["error"] == "Captcha is required."
    end

    test "with wrong credentials(null bytes) and redirect when valid", %{conn: conn} do
      Innerpeace.Db.Base.UserContext.create_admin(%{
        username: "admin",
        password: "p@ssw0rd",
        payroll_code: "1",
        is_admin: true,
        first_time: false
      })
      conn = post conn, session_path(conn, :create), session: %{
        username: "\x00",
        password: "p@ssw0rd",
        payroll_code: "1",
        captcha: "generated_captcha_code"
      }
      assert redirected_to(conn) == session_path(conn, :new)
      assert conn.private[:phoenix_flash]["error"] == "Error logging in. Please try again!"
    end
  end

  test "Delete session on logout", %{conn: conn} do
    # user = insert(:user, is_admin: true)
    # conn = sign_in(build_conn(), user)

    conn = delete conn, session_path(conn, :delete)
    assert redirected_to(conn) == "/sign_in"
  end

  # test "sets the permissions", %{conn: conn, user: user} do
  #   conn = post conn, session_path(conn, :create), session: %{
  #     username: user.username,
  #     password: "P@ssw0rd"
  #   }
  #   permissions = get_session(conn, :permissions)
  #   assert Enum.member?(permissions, "manage_users")
  #   assert Enum.member?(permissions, "manage_roles")
  # end

  test "renders change_password", %{conn: conn} do
    # user = insert(:user, is_admin: true)
    # conn = sign_in(build_conn(), user)

    conn = get conn, session_path(conn, :change_password)
    assert html_response(conn, 200) =~ "Change Password"
  end
end
