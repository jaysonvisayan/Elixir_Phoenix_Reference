defmodule MemberLinkWeb.Api.V1.UserControllerTest do
  # use Innerpeace.Db.SchemaCase, async: true
  use MemberLinkWeb.ConnCase

  alias MemberLink.Guardian.Plug
  alias MemberLinkWeb.Api.V1.UserView
  alias MemberLinkWeb.Api.ErrorView
  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    User
  }
  # alias Innerpeace.Db.Base.{
  #   UserContext
  # }
  alias MemberLink.Guardian, as: MG

  setup do
    account_group =
      :account_group
      |> insert(name: "test account")

    member =
      :member
      |> insert(
        status: "Active",
        account_group: account_group,
        card_no: "6012127890121234",
        gender: "male"
      )
    {:ok, user} = Repo.insert(User.admin_changeset(
      %User{
        username: "test_user",
        password: "P@ssw0rd",
        is_admin: false,
        verification_code: "1234",
        verification: true,
        first_name: "Shane",
        middle_name: "Dolot",
        last_name: "Dela Rosa",
        email: "test@user.com",
        mobile: "09277435476",
        gender: "Male",
        member_id: member.id,
        verification_expiry: Ecto.DateTime.from_erl(:erlang.localtime)
      })
    )

    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = MemberLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    token = Plug.current_token(conn)
    conn1 = build_conn()
           |> authenticated(user)

    {:ok, %{user: user, conn: conn, token: token, conn1: conn1}}
  end

  test "update_username with valid params", %{conn: conn, token: token} do
    params = %{"username" => "abbymae"}

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put("/api/v1/user/username", params)

    left = json_response(conn, 200)
    right = %{
      "message" => "Successfully updated username",
      "code" => 200
    }

    assert left == right
  end

  test "update_username with same username", %{conn: conn, token: token} do
    params = %{"username" => "test_user"}

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put("/api/v1/user/username", params)

    left = json_response(conn, 400)
    right = %{
      "message" => "Username is the same",
      "code" => 400
    }

    assert left == right
  end

  test "update_username with invalid params", %{conn: conn, token: token} do
    params = %{"username" => ""}

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put("/api/v1/user/username", params)

    left = json_response(conn, 400)
    right = %{
      "message" => "Didn't pass validation",
      "code" => 400
    }

    assert left == right
  end

  test "update_username with username already exist", %{conn: conn, token: token} do
    {:ok, _second_user} = Repo.insert(%User{username: "test_user01", password: "P@ssw0rd"})

    params = %{"username" => "test_user01"}

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put("/api/v1/user/username", params)

    left = json_response(conn, 400)
    right = %{
      "message" => "Didn't pass validation",
      "code" => 400
    }

    assert left == right
  end

  test "update_password with valid params", %{conn: conn, token: token} do
    params = %{
      "old_password" => "P@ssw0rd",
      "password" => "P@ssw0rd1",
      "password_confirmation" => "P@ssw0rd1"
    }

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put("/api/v1/user/password", params)

    left = json_response(conn, 200)
    right = %{
      "message" => "Successfully updated password",
      "code" => 200
    }

    assert left == right
  end

  test "update_password with empty old password", %{conn: conn, token: token} do
    params = %{
      "old_password" => "",
      "password" => "P@ssw0rd1",
      "password_confirmation" => "P@ssw0rd1"
    }

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put("/api/v1/user/password", params)

    left = json_response(conn, 400)
    right = %{
      "message" => "Old password can't be blank",
      "code" => 400
    }

    assert left == right
  end

  test "update_password with invalid params", %{conn: conn, token: token} do
    params = %{
      "old_password" => "P@ssw0rd",
      "password" => "",
      "password_confirmation" => ""
    }

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put("/api/v1/user/password", params)

    changeset = conn.assigns.changeset
    left = json_response(conn, 400)
    right = render_error_json("changeset_error_api.json",changeset: changeset)

    assert left == right
  end

  test "update_password with passwords not match", %{conn: conn, token: token} do
    params = %{
      "old_password" => "P@ssw0rd",
      "password" => "P@ssw0rd1",
      "password_confirmation" => "P@ssw0rd2"
    }

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put("/api/v1/user/password", params)

    changeset = conn.assigns.changeset
    left = json_response(conn, 400)
    right = render_error_json("changeset_error_api.json",changeset: changeset)

    assert left == right
  end

  test "card_verification/1 verifies card of member", %{conn1: conn} do
    member = insert(:member, card_no: "1234567890111111", birthdate: Ecto.Date.cast!("1992-06-23"), status: "Active")
    card_params = %{
      "cardnumber" => "1234567890111111",
      "birthday" => "06/23/1992"
    }
    conn =
      conn
      |> post(user_path(conn, :card_verification, card_params))
    assert json_response(conn, 200) == render_json("user.json", member: member)
  end

#  test "card_verification/1 returns error message when no members are found", %{conn: conn} do
#    member = insert(:member, card_no: "1234567890", birthdate: Ecto.Date.cast!("1992-06-23"))
#
#    card_params = %{
#      "cardnumber" => "1234567899",
#      "birthday" => "06/23/1992"
#    }
#    conn =
#      conn
#      |> post(user_path(conn, :card_verification, card_params))
#    return = %{
#      "message" => "Member not found",
#      "code" => 400
#    }
#    assert json_response(conn, 400) == return
#  end

#  test "card_verification/1 returns error message when card number is blank", %{conn: conn} do
#    member = insert(:member, card_no: "1234567890", birthdate: Ecto.Date.cast!("1992-06-23"))
#
#    card_params = %{
#      "cardnumber" => "",
#      "birthday" => "06/23/1992"
#    }
#    conn =
#      conn
#      |> post(user_path(conn, :card_verification, card_params))
#    return = %{
#      "message" => "Card number can't be blank",
#      "code" => 400
#    }
#    assert json_response(conn, 400) == return
#  end

  test "card_verification/1 returns error message when birthday is blank", %{conn: conn} do
    insert(:member, card_no: "1234567890", birthdate: Ecto.Date.cast!("1992-06-23"))

    card_params = %{
      "cardnumber" => "1234567890",
      "birthday" => ""
    }
    conn =
      conn
      |> post(user_path(conn, :card_verification, card_params))
    return = %{
      "message" => "Birthday can't be blank",
      "code" => 400
    }
    assert json_response(conn, 400) == return
  end

  test "card_verification/1 returns error message when user is already a registered member", %{conn: conn} do
    member = insert(:member, card_no: "1234567890", birthdate: Ecto.Date.cast!("1992-06-23"))
    insert(:user, member: member)

    card_params = %{
      "cardnumber" => "1234567890",
      "birthday" => "06/23/1992"
    }
    conn =
      conn
      |> post(user_path(conn, :card_verification, card_params))
    return = %{
      "message" => "Member is already registered",
      "code" => 400
    }
    assert json_response(conn, 400) == return
  end

  # test "register/1 registers user in member", %{conn: conn} do
  #   member = insert(:member)

  #   user_params = %{
  #     "username" => "username",
  #     "password" => "P@ssw0rd",
  #     "password_confirmation" => "P@ssw0rd",
  #     "email" => "test@user2.com",
  #     "mobile" => "09283457296",
  #     "member_id" => member.id
  #   }

  #  conn =
  #    conn
  #    |> post(user_path(conn, :register, user_params))

  #   token = Plug.current_token(conn)
  #   claims = Plug.current_claims(conn)
  #   exp =
  #     claims
  #     |> Map.get("exp")
  #     |> Ecto.DateTime.from_unix!(:second)
  #     |> Ecto.DateTime.to_iso8601
  #   user = conn.private.guardian_default_resource
  #   assert json_response(conn, 200) == %{"user_id" => user.id, "token" => "#{token}",
  #     "expiry" => exp, "verified" => false}
  # end

  defp render_json(template, assigns) do
    assigns = Map.new(assigns)

    view = UserView.render(template, assigns)
    view
    |> Poison.encode!
    |> Poison.decode!
  end

  test "sms_verification verifies user first login", %{conn: conn, token: token, user: user} do
    Repo.update(User.expiry_changeset(user,%{"verification_expiry" => Ecto.DateTime.from_erl(:erlang.localtime)}))
    claims = Plug.current_claims(conn)
    exp = Map.get(claims, "exp")
    params = %{"pin" => 1234}
    conn =
      conn
      |> put(user_path(conn, :sms_verification, params))
    assert json_response(conn, 200) == render_json("sms_verification.json", user: user,
                                                   token: token, exp: exp)
  end

  test "sms_verification returns invalid pin when pin is invalid", %{conn: conn, user: user} do
    Repo.update(User.expiry_changeset(user,%{"verification_expiry" => Ecto.DateTime.from_erl(:erlang.localtime)}))
    claims = Plug.current_claims(conn)
    _exp = Map.get(claims, "exp")
    params = %{"pin" => ""}
    conn =
      conn
      |> put(user_path(conn, :sms_verification, params))
    assert json_response(conn, 400) == %{
      "message" => "Invalid pin",
      "code" => 400
    }
  end

  test "sms_verification returns user locked when user status is locked", %{conn: conn, user: user} do
    Repo.update(User.expiry_changeset(user,%{"verification_expiry" => Ecto.DateTime.from_erl(:erlang.localtime)}))
    Repo.update(User.status_changeset(user,%{status: "locked"}))
    claims = Plug.current_claims(conn)
    _exp = Map.get(claims, "exp")
    params = %{"pin" => 1234}
    conn =
      conn
      |> put(user_path(conn, :sms_verification, params))
    assert json_response(conn, 400) == %{
      "message" => "User is locked please reset your password",
      "code" => 400
    }

  end

  test "sms_verification returns user locked when user pin expired", %{conn: conn, user: user} do
    Repo.update(User.expiry_changeset(user,%{"verification_expiry" => Ecto.DateTime.cast!("2011-10-30T10:10:10")}))
    claims = Plug.current_claims(conn)
    _exp = Map.get(claims, "exp")
    params = %{"pin" => 1234}
    conn =
      conn
      |> put(user_path(conn, :sms_verification, params))
    assert json_response(conn, 404) == %{
      "message" => "pin expired",
      "code" => 404
    }

  end

  test "request_pin/1 resends pin code to user", %{conn: conn} do
    conn =
     conn
     |> get(user_path(conn, :request_pin))
    user = MG.current_resource_api(conn)
    assert json_response(conn, 200) == render_json("request_pin.json", message: "Successfully sent the PIN to the user's mobile number and email", code: 200, exp: user.verification_expiry)
  end

# test "forgot_username sends user's username to email", %{conn: conn} do
#   params = %{
#     "username" => "",
#     "recovery" => "email",
#     "text" => "test@user.com"
#   }

#   conn =
#     conn
#     |> post(user_path(conn, :forgot_username, params))
#   assert json_response(conn, 200) == render_json("forgot_credential.json", message: "Successfully sent the username to the user's email", code: 200)
# end

  test "forgot_username returns error message when user's email is blank", %{conn: conn} do
    params = %{
      "recovery" => "email",
      "text" => ""
    }

    conn =
      conn
      |> post(user_path(conn, :forgot_username, params))
    changeset = conn.assigns.changeset
    assert json_response(conn, 400) == render_error_json("changeset_error_api.json", changeset: changeset)
  end

  test "forgot_username returns error message when user's email is not found", %{conn: conn} do
    params = %{
      "recovery" => "email",
      "text" => "asdasd@asd.com"
    }

    conn =
      conn
      |> post(user_path(conn, :forgot_username, params))
    assert json_response(conn, 404) == %{"message" => "Email not found", "code" => 404}
  end

  test "forgot_username sends user's username to mobile", %{conn: conn} do
    params = %{
      "recovery" => "mobile",
      "text" => "09277435476"
    }

    conn =
      conn
      |> post(user_path(conn, :forgot_username, params))
    assert json_response(conn, 200) == render_json("forgot_credential.json", message: "Successfully sent the username to the user's mobile number", code: 200)
  end

  test "forgot_username returns error message when user's mobile is blank", %{conn: conn} do
    params = %{
      "recovery" => "mobile",
      "text" => ""
    }

    conn =
      conn
      |> post(user_path(conn, :forgot_username, params))
    changeset = conn.assigns.changeset
    assert json_response(conn, 400) == render_error_json("changeset_error_api.json", changeset: changeset)
  end

  test "forgot_username returns error message when user's mobile is not found", %{conn: conn} do
    params = %{
      "recovery" => "mobile",
      "text" => "99999999999"
    }

    conn =
      conn
      |> post(user_path(conn, :forgot_username, params))
    assert json_response(conn, 404) == %{"message" => "Mobile not found", "code" => 404}
  end

# test "forgot_password sends request PIN to user's email", %{conn: conn} do
#   params = %{
#     "username" => "test_user",
#     "recovery" => "email",
#     "text" => "test@user.com"
#   }

#   conn =
#     conn
#     |> post(user_path(conn, :forgot_password, params))
#   user = conn.private.guardian_default_resource
#   assert json_response(conn, 200) == render_json("forgot_credential_password.json", message: "Successfully sent the PIN to the user's email", code: 200, user_id: user.id)
# end

  # test "forgot_password returns error message when user's email is blank", %{conn: conn} do
  #   params = %{
  #     "username" => "test_user",
  #     "recovery" => "email",
  #     "text" => ""
  #   }

  #   conn =
  #     conn
  #     |> post(user_path(conn, :forgot_password, params))
  #   changeset = conn.assigns.changeset
  #   assert json_response(conn, 400) == render_error_json("changeset_error_api.json", changeset: changeset)
  # end

  # test "forgot_password returns error message when user's email is not found", %{conn: conn} do
  #   params = %{
  #     "username" => "test_user",
  #     "recovery" => "email",
  #     "text" => "asdasd@asd.com"
  #   }

  #   conn =
  #     conn
  #     |> post(user_path(conn, :forgot_password, params))
  #   assert json_response(conn, 404) == %{"message" => "User not found", "code" => 404}
  # end

  test "forgot_password sends PIN to user's mobile", %{conn: conn} do
    params = %{
      "username" => "test_user",
      "recovery" => "mobile",
      "text" => "09277435476"
    }
    conn =
      conn
      |> post(user_path(conn, :forgot_password, params))
    user = MG.current_resource_api(conn)
    assert json_response(conn, 200) |> Map.delete("pin_expiry") ==
      render_json("forgot_credential_password.json", message: "Successfully sent the PIN to the user's mobile number", code: 200, user: user)
      |> Map.delete("pin_expiry")
  end

  test "forgot_password returns error message when user's status is not active", %{conn: conn} do
    member = insert(:member)
    insert(:user, username: "test_invalid", mobile: "09199046601", member: member)
    params = %{
      "username" => "test_invalid",
      "recovery" => "mobile",
      "text" => "09199046601"
    }

    conn =
      conn
      |> post(user_path(conn, :forgot_password, params))
    assert json_response(conn, 400) == %{"code" => 400, "message" => "The member you have entered is not active"}
  end

  test "forgot_password returns error message when user's mobile is blank", %{conn: conn} do
    params = %{
      "username" => "test_user",
      "recovery" => "mobile",
      "text" => ""
    }

    conn =
      conn
      |> post(user_path(conn, :forgot_password, params))
    changeset = conn.assigns.changeset
    assert json_response(conn, 400) == render_error_json("changeset_error_api.json", changeset: changeset)
  end

  test "forgot_password returns error message when user's mobile is not found", %{conn: conn} do
    params = %{
      "username" => "test_user",
      "recovery" => "mobile",
      "text" => "99999999999"
    }

    conn =
      conn
      |> post(user_path(conn, :forgot_password, params))
    assert json_response(conn, 404) == %{"message" => "User not found", "code" => 404}
  end

  test "forgot_password_confirm validates sent verification code of user", %{conn: conn, user: user} do
    params = %{
      "user_id" => user.id,
      "verification_code" => 1234
    }

    conn =
      conn
      |> put(user_path(conn, :forgot_password_confirm, params))
    assert json_response(conn, 200) == %{"verified" => false, "user_id" => user.id, "message" => "Valid verification code", "code" => 200}
  end

  test "forgot_password_confirm returns error message when verification code is invalid", %{conn: conn, user: user} do
    params = %{
      "user_id" => user.id,
      "verification_code" => 1231
    }

    conn =
      conn
      |> put(user_path(conn, :forgot_password_confirm, params))
    assert json_response(conn, 400) == %{"message" => "Invalid pin", "code" => 400}
  end

  test "forgot_password_confirm returns error message when user is not found", %{conn: conn} do
    params = %{
      "user_id" => "eac9fc13-6ce1-4e86-b29e-4a2f20c691e4",
      "verification_code" => 1234
    }

    conn =
      conn
      |> put(user_path(conn, :forgot_password_confirm, params))
    assert json_response(conn, 404) == %{"message" => "User not found", "code" => 404}
  end

  test "forgot_password_confirm returns error message when user_id is blank", %{conn: conn} do
    params = %{
      "user_id" => "",
      "verification_code" => 1234
    }

    conn =
      conn
      |> put(user_path(conn, :forgot_password_confirm, params))
    assert json_response(conn, 400) == %{"message" => "user id can't be blank", "code" => 400}
  end

  test "forgot_password_confirm returns error message when verification_code is blank", %{conn: conn} do
    params = %{
      "user_id" => "eac9fc13-6ce1-4e86-b29e-4a2f20c691e4",
      "verification_code" => ""
    }

    conn =
      conn
      |> put(user_path(conn, :forgot_password_confirm, params))
    assert json_response(conn, 400) == %{"message" => "verification code can't be blank", "code" => 400}
  end

  test "forgot_password_confirm returns error message when user id and verification_code is blank", %{conn: conn} do
    params = %{
      "user_id" => "",
      "verification_code" => ""
    }

    conn =
      conn
      |> put(user_path(conn, :forgot_password_confirm, params))
    assert json_response(conn, 400) == %{"message" => "user id and verification code can't be blank", "code" => 400}
  end

  test "forgot_password_reset successfully creates new password for user", %{conn: conn, user: user} do
    params = %{
      "user_id" => user.id,
      "password" => "P@ssw0rd99",
      "password_confirmation" => "P@ssw0rd99"
    }
    conn =
      conn
      |> put(user_path(conn, :forgot_password_reset, params))

    token = Plug.current_token(conn)
    claims = Plug.current_claims(conn)
    exp =
      claims
      |> Map.get("exp")
      |> Ecto.DateTime.from_unix!(:second)
      |> Ecto.DateTime.to_iso8601
    user = MG.current_resource_api(conn)
    assert json_response(conn, 200) == %{"user_id" => user.id, "token" => "#{token}",
      "expiry" => exp, "verified" => true}
  end

  test "forgot_password_reset returns error message when password is the same as previous password", %{conn: conn, user: user} do
    params = %{
      "user_id" => user.id,
      "password" => "P@ssw0rd",
      "password_confirmation" => "P@ssw0rd"
    }
    conn =
      conn
      |> put(user_path(conn, :forgot_password_reset, params))
    assert json_response(conn, 400) == %{"message" => "Cannot use old password", "code" => 400}
  end

  test "forgot_password_reset returns error message when password or password confirmation is blank", %{conn: conn, user: user} do
    params = %{
      "user_id" => user.id,
      "password" => "",
      "password_confirmation" => "P@ssw0rd99"
    }
    conn =
      conn
      |> put(user_path(conn, :forgot_password_reset, params))
    changeset = conn.assigns.changeset
    assert json_response(conn, 400) == render_error_json("changeset_error_api.json", changeset: changeset)
  end

  test "forgot_password_reset returns error message when password and password confirmation is blank", %{conn: conn, user: user} do
    params = %{
      "user_id" => user.id,
      "password" => "",
      "password_confirmation" => "P@ssw0rd99"
    }
    conn =
      conn
      |> put(user_path(conn, :forgot_password_reset, params))
    changeset = conn.assigns.changeset
    assert json_response(conn, 400) == render_error_json("changeset_error_api.json", changeset: changeset)
  end

  test "forgot_password_reset returns error message when user_id is blank", %{conn: conn} do
    params = %{
      "user_id" => "",
      "password" => "",
      "password_confirmation" => "P@ssw0rd99"
    }
    conn =
      conn
      |> put(user_path(conn, :forgot_password_reset, params))
    assert json_response(conn, 400) == %{"message" => "User id can't be blank", "code" => 400}
  end

  test "forgot_password_reset returns error message when user's not found", %{conn: conn} do
    params = %{
      "user_id" => "43badecb-6d2b-4df8-8474-2038065d4f4a",
      "password" => "P@ssw0rd99",
      "password_confirmation" => "P@ssw0rd99"
    }
    conn =
      conn
      |> put(user_path(conn, :forgot_password_reset, params))
    assert json_response(conn, 404) == %{"message" => "User not found", "code" => 404}
  end

  defp render_error_json(template, assigns) do
    assigns = Map.new(assigns)

    view = ErrorView.render(template, assigns)
    view
    |> Poison.encode!
    |> Poison.decode!
  end

  test "view_account renders show account form", %{conn1: conn} do
    conn =
      conn
      |> get(user_path(conn, :view_account, "en"))

    result =
      conn
      |> html_response(200)

    assert result =~ "My Account"
  end

  test "edit_account renders edit account form", %{conn1: conn} do
    conn =
      conn
      |> get(user_path(conn, :edit_account, "en"))

    result =
      conn
      |> html_response(200)

    assert result =~ "Old Password"
  end

  test "update_account with valid params", %{conn1: conn} do
    params = %{
      old_password: "P@ssw0rd",
      password: "P@ssw0rd1",
      password_confirmation: "P@ssw0rd1"
    }

    conn =
      conn
      |> post(user_path(conn, :update_account, "en"), user: params)

    result =
      conn
      |> get_flash(:info)

    assert result == "Password successfully updated."
  end

  test "update_account without old password", %{conn1: conn} do
    params = %{
      password: "P@ssw0rd1",
      password_confirmation: "P@ssw0rd1"
    }

    conn =
      conn
      |> post(user_path(conn, :update_account, "en"), user: params)

    result =
      conn
      |> get_flash(:error)

    assert result == "Please enter old password"
  end

  test "update_account without password", %{conn1: conn} do
    params = %{
      old_password: "P@ssw0rd",
      password_confirmation: "P@ssw0rd1"
    }

    conn =
      conn
      |> post(user_path(conn, :update_account, "en"), user: params)

    result =
      conn
      |> get_flash(:error)

    assert result == "Please enter new password"
  end

  test "update_account with invalid password", %{conn1: conn} do
    params = %{
      old_password: "P@ssw0rd123",
      password: "P@ssw0rd1",
      password_confirmation: "P@ssw0rd1"
    }

    conn =
      conn
      |> post(user_path(conn, :update_account, "en"), user: params)

    result =
      conn
      |> html_response(200)

    assert result =~ "Invalid password"
  end

  test "validate_old_password with valid password", %{conn1: conn} do
    params = %{
      user: %{
        old_password: "P@ssw0rd"
      }
    }

    conn =
      conn
      |> post(user_path(conn, :validate_old_password, "en"), params)

    result =
      json_response(conn, 200)

    assert is_nil(result)
  end

  test "validate_old_password with invalid password", %{conn1: conn} do
    params = %{
      user: %{
        old_password: "P@ssw0rd1"
      }
    }

    conn =
      conn
      |> post(user_path(conn, :validate_old_password, "en"), params)

    result =
      conn
      |> json_response(200)

    assert result == "Invalid password"
  end

  test "edit_profile renders edit profile form", %{conn1: conn} do
    conn =
      conn
      |> get(user_path(conn, :edit_profile, "en"))

    result =
      conn
      |> html_response(200)

    assert result =~ "Profile"
  end

  test "update_profile with valid params", %{conn1: conn} do
    params = %{
      photo: "test"
    }

    conn =
      conn
      |> post(user_path(conn, :update_profile, "en"), member: params)

    result =
      conn
      |> get_flash(:info)

    assert result == "Photo successfully uploaded."
  end

  test "request_profile_correction renders profile correction form", %{conn1: conn} do
    conn =
      conn
      |> get(user_path(conn, :request_profile_correction, "en"))

    result =
      conn
      |> html_response(200)

    assert result =~ "Correction"
  end

#   test "send_request_prof_cor with valid params", %{conn: conn} do
#     params = %{
#       id_card: "test",
#       first_name: "test"
#     }

#     conn =
#       conn
#       |> post(user_path(conn, :send_request_prof_cor, "en"), profile_correction: params)

#     result =
#       conn
#       |> html_response(200)

#     assert result =~ "Your personal information correction request has been sent"
#   end

  test "send_request_prof_cor with invalid params", %{conn1: conn} do
    params = %{
      id_card: "test"
    }

    conn =
      conn
      |> post(user_path(conn, :send_request_prof_cor, "en"), profile_correction: params)

    result =
      conn
      |> html_response(200)

    assert result =~ "One of these fields must be present: [Name, Birth Date, Gender]"

  end

  test "edit_contact_details renders edit contact details form", %{conn1: conn} do
    conn =
      conn
      |> get(user_path(conn, :edit_contact_details, "en"))

    result =
      conn
      |> html_response(200)

    assert result =~ "Contact Details"
  end

  test "update_contact_details with valid params", %{conn1: conn} do
    params = %{
      mobile: "09156826861",
      mobile_confirmation: "09156826861",
      email: "janna_delacruz@medilink.ph",
      email_confirmation: "janna_delacruz@medilink.ph"
    }

    conn =
      conn
      |> post(user_path(conn, :update_contact_details, "en"), contact: params)

    result =
      conn
      |> get_flash(:info)

    assert result == "Contact Details successfully updated."
  end

  test "update_contact_details with invalid params", %{conn1: conn} do
    params = %{
      mobile: "09156826861",
      mobile_confirmation: "091568268",
      email: "janna_delacruz@medilink.ph",
      email_confirmation: "janna_delacruz@medilink.ph"
    }

    conn =
      conn
      |> post(user_path(conn, :update_contact_details, "en"), contact: params)

    result =
      conn
      |> html_response(200)

    assert result =~ "Mobile number does"
  end
end
