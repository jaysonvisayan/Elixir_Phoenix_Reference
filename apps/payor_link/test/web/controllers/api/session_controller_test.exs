defmodule Innerpeace.PayorLink.Web.Api.SessionControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase

  alias Innerpeace.Db.Schemas.User
  alias Innerpeace.Db.Base.Api.UtilityContext
  alias Ecto.Changeset

  setup do
    user = insert(:user, username: "masteradmin", password: "P@ssw0rd")
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"

    conn = PayorLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Guardian.Plug.current_token(conn)

    {:ok, %{user: user, jwt: jwt, conn: conn}}
  end

  test "Sign in with valid credentials" do
    {:ok, user} = Innerpeace.Db.Repo.insert(User.admin_changeset(%User{}, %{
      username: "username",
      password: "P@ssw0rd",
      is_admin: true
    }))

    conn =
      build_conn()
      |> post("/api/v1/sign_in", %{
        username: "username",
        password: "P@ssw0rd"
      })

    token = Guardian.Plug.current_token(conn)

    assert json_response(conn, 200) == %{"user_id" => user.id, "token" => "#{token}", "validated" => true}
  end

  test "Sign in with nil hashed_password" do
    conn =
      build_conn()
      |> post("/api/v1/sign_in", %{
        username: "masteradmin",
        password: "P@ssw0rd"
      })

    assert json_response(conn, 403) == %{"error" => %{"message" => "Unauthorized user"}}
  end

  test "Sign in with invalid credentials" do
    conn =
      build_conn()
      |> post("/api/v1/sign_in", %{
        username: "username",
        password: "P@ssw0rd"
      })

    assert json_response(conn, 404) == %{"error" => %{"message" => "Not Found!"}}
  end

  test "Sign out with token", %{jwt: jwt} do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get("/api/v1/sign_out")

    assert json_response(conn, 200) == %{"message" => "signed out!"}
  end

  test "Sign out with invalid token"do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer 12313213213")
      |> recycle
      |> get("/api/v1/sign_out")


    assert json_response(conn, 401) == %{"error" => %{"message" => "Unauthorized"}}
  end

  test "Sign out without token" do
    conn =
      build_conn()
      |> get("/api/v1/sign_out")

    assert json_response(conn, 401) == %{"error" => %{"message" => "Unauthorized"}}
  end

  describe "Render's forgot password" do
    test "forgot password html", %{conn: conn} do
      conn = get conn, session_path(conn, :forgot_password)
      result =
        conn
        |> html_response(200)
      assert result =~ "Forgot Password?"
    end
  end

  describe "Sending verification" do
    test "with valid parameters using mobile", %{conn: conn} do
      user = insert(:user, username: "testuser", password: "P@ssw0rd", mobile: "09277435476")
      conn = post conn, session_path(conn, :send_verification2), %{session: %{
        userinfo: "09277435476"
      }}
      assert redirected_to(conn) == "/verify_code_sms/#{user.id}"
    end

    test "with invalid parameters using mobile", %{conn: conn} do
      insert(:user, username: "testuser", password: "P@ssw0rd", mobile: "09277435476")
      conn = post conn, session_path(conn, :send_verification2), %{session: %{
        userinfo: "0927743547"
      }}
      assert conn.assigns.error == "We don't recognize the email address/phone number you have entered. Try entering it again."
    end

    # test "with valid parameters using email", %{conn: conn} do
    #   user = insert(:user, username: "testuser", password: "P@ssw0rd", email: "test@email.com")
    #   insert(:login_ip_address, ip_address: "172.17.0.1", attempts: 0, verify_attempts: 0)
    #   conn = post conn, session_path(conn, :send_verification2), %{session: %{
    #     userinfo: "test@email.com"
    #   }}
    #   assert conn.assigns.info == "We've sent you a email with instructions on how to reset your password"
    # end

    test "with invalid parameters using email", %{conn: conn} do
      insert(:user, username: "testuser", password: "P@ssw0rd", email: "test@email.com")
      insert(:login_ip_address, ip_address: UtilityContext.get_ip(conn) , attempts: 0, verify_attempts: 0)
      conn = post conn, session_path(conn, :send_verification2), %{session: %{
        userinfo: "error@email.com"
      }}
      assert conn.assigns.error == "We don't recognize the email address/phone number you have entered. Try entering it again."
    end
  end

  describe "Resending code" do
    test "with valid parameters", %{conn: conn} do
      user = insert(:user, username: "testuser", password: "P@ssw0rd", mobile: "09277435476")
      insert(:login_ip_address, ip_address: "172.17.0.1", attempts: 0, verify_attempts: 0)
      conn = get conn, session_path(conn, :resend_code, user.id)
      assert get_flash(conn, :info) == "Verification code has been resent via SMS!"
    end
  end

  describe "Verification of code" do
    test "with valid parameters", %{conn: conn} do
      user = insert(:user, username: "testuser", password: "P@ssw0rd", mobile: "09277435476", verification_code: "102985", verification_expiry: Ecto.DateTime.from_erl(:erlang.localtime))
      insert(:login_ip_address, ip_address: "172.17.0.1", attempts: 0, verify_attempts: 0)
      conn = post conn, session_path(conn, :code_verification, user.id), %{user: %{"verification_code" => ["1", "0", "2", "9", "8", "5"]}}
      assert get_flash(conn, :info) == "Code Verified!"
    end

    test "with invalid parameters", %{conn: conn} do
      user = insert(:user, username: "testuser", password: "P@ssw0rd", mobile: "09277435476", verification_code: "000000", verification_expiry: Ecto.DateTime.from_erl(:erlang.localtime))
      insert(:login_ip_address, ip_address: "172.17.0.1", attempts: 0, verify_attempts: 0)
      conn = post conn, session_path(conn, :code_verification, user.id), %{user: %{"verification_code" => ["1", "0", "2", "9", "8", "5"]}}
      assert get_flash(conn, :error) == "Invalid Verification Code!"
      assert redirected_to(conn) == "/verify_code_sms/#{user.id}"
    end

    test "with expired verification code", %{conn: conn} do
      user = insert(:user, username: "testuser", password: "P@ssw0rd", mobile: "09277435476", verification_code: "102985", verification_expiry: Ecto.DateTime.cast!("2011-10-30T10:10:10"))
      insert(:login_ip_address, ip_address: "172.17.0.1", attempts: 0, verify_attempts: 0)
      conn = post conn, session_path(conn, :code_verification, user.id), %{user: %{"verification_code" => ["1", "0", "2", "9", "8", "5"]}}
      assert get_flash(conn, :error) == "Verification code has expired, request for a new code"
      assert redirected_to(conn) == "/verify_code_sms/#{user.id}"
    end
  end

  describe "Rendering forgot password" do
    test "with valid user", %{conn: conn} do
      user = insert(:user, username: "testuser", password: "P@ssw0rd", mobile: "09277435476", reset_token: Ecto.UUID.generate())
      conn = get conn, session_path(conn, :reset_password, user.reset_token)
      result =
        conn
        |> html_response(200)
      assert result =~ "Reset password"
    end

    test "with invalid user", %{conn: conn} do
      user = insert(:user, username: "testuser", password: "P@ssw0rd", mobile: "09277435476", reset_token: Ecto.UUID.generate())
      conn = get conn, session_path(conn, :reset_password, user.id)
      assert get_flash(conn, :error) == "User not found!"
      assert redirected_to(conn) == "/forgot_password"
    end
  end

  describe "Updates Password" do
    test "with valid parameters", %{conn: conn} do
      {:ok, user} = Innerpeace.Db.Repo.insert(User.admin_changeset(%User{}, %{
        username: "username",
        password: "P@ssw0rd",
        is_admin: true,
      }))
      {:ok, user} = Innerpeace.Db.Repo.update(Changeset.change user, mobile: "09277435476", reset_token: Ecto.UUID.generate())
      params = %{
        user: %{password: "P@ssw0rd1234", password_confirmation: "P@ssw0rd1234"}
      }
      conn = put conn, session_path(conn, :update_password, user.reset_token), params
      assert get_flash(conn, :info) == "Your password has been successfully changed."
      assert redirected_to(conn) == "/sign_in"
    end

    test "with invalid parameters/1", %{conn: conn} do
      {:ok, user} = Innerpeace.Db.Repo.insert(User.admin_changeset(%User{}, %{
        username: "username",
        password: "P@ssw0rd1234",
        is_admin: true,
      }))
      {:ok, user} = Innerpeace.Db.Repo.update(Changeset.change user, mobile: "09277435476", reset_token: Ecto.UUID.generate())
      params = %{
        user: %{password: "P@ssw0rd1234", password_confirmation: "P@ssw0rd1234"}
      }
      conn = put conn, session_path(conn, :update_password, user.reset_token), params
      assert conn.assigns.error == "You have used that password before, enter new one"
    end

    test "with invalid parameters/2", %{conn: conn} do
      {:ok, user} = Innerpeace.Db.Repo.insert(User.admin_changeset(%User{}, %{
        username: "username",
        password: "P@ssw0rd1234",
        is_admin: true,
      }))
      {:ok, user} = Innerpeace.Db.Repo.update(Changeset.change user, mobile: "09277435476", reset_token: Ecto.UUID.generate())
      params = %{
        user: %{password: "P@ssw0rd", password_confirmation: "P@ssw0rd123"}
      }
      conn = put conn, session_path(conn, :update_password, user.reset_token), params
      assert conn.assigns.error == "Password and Password Confirmation doesn't match!"
    end

    test "with invalid parameters/3", %{conn: conn} do
      {:ok, user} = Innerpeace.Db.Repo.insert(User.admin_changeset(%User{}, %{
        username: "username",
        password: "P@ssw0rd",
        is_admin: true,
      }))
      {:ok, user} = Innerpeace.Db.Repo.update(Changeset.change user, mobile: "09277435476", reset_token: Ecto.UUID.generate())
      params = %{
        user: %{password: "P@ssw0r", password_confirmation: "P@ssw0r"}
      }
      conn = put conn, session_path(conn, :update_password, user.reset_token), params
      assert conn.assigns.error == "Password must be at least 8 characters and at most 128 character"
    end
  end
end
