defmodule MemberLinkWeb.Api.V1.UserController do
  use MemberLinkWeb, :controller
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  import Logger

  alias Innerpeace.MemberLink.{
    EmailSmtp,
    Mailer
  }
  alias MemberLink.Guardian.Plug
  alias MemberLinkWeb.Api.V1.SessionController
  alias MemberLinkWeb.Api.V1.UserView
  alias MemberLinkWeb.Api.ErrorView
  alias Innerpeace.Db.{
    Utilities.SMS,
    Schemas.User,
    Schemas.Member,
    Base.UserContext,
    Base.MemberContext,
    Base.Api.UtilityContext
  }
  alias MemberLink.Guardian, as: MG

  def update_username(conn, params) do
    user = MG.current_resource_api(conn)

    if user.username != params["username"] do
      with {:ok, user} <- UserContext.update_username(user, params),
           {:ok, user} <- UserContext.attempts_reset(user, %{attempts: nil}),
           {:ok, user} <- UserContext.update_user_status_active(user)
      do
        conn
        |> SessionController.login_new(user)
        |> render("update_username_password.json", message: "Successfully updated username", code: 200)
      else
        {:error, _changeset} ->
          error_msg(conn, 400, "Didn't pass validation")
        _ ->
          error_msg(conn, 500, "Server error")
      end
    else
      error_msg(conn, 400, "Username is the same")
    end
  end

  def update_password(conn, params) do
    user = MG.current_resource_api(conn)

    cond do
      checkpw(params["old_password"], user.hashed_password) ->
        with {:ok, user} <- UserContext.reset_password_memberlink(user, params),
             {:ok, user} <- UserContext.attempts_reset(user, %{attempts: nil}),
             {:ok, user} <- UserContext.update_user_status_active(user)
        do
          conn
          |> SessionController.login_new(user)
          |> render("update_username_password.json", message: "Successfully updated password", code: 200)
        else
          {:old_password} ->
            error_msg(conn, 400, "Cannot use old password")
          {:error, changeset} ->
            conn
            |> put_status(400)
            |> render(ErrorView, "changeset_error_api.json", changeset: changeset)
        _ ->
          error_msg(conn, 500, "Server error")
        end
      params["old_password"] == "" && params["password"] == "" && params["password_confirmation"] == "" ->
        error_msg(conn, 400, "All fields are required")
      params["old_password"] == "" || is_nil(params["old_password"]) ->
        error_msg(conn, 400, "Old password can't be blank")
      true ->
        error_msg(conn, 400, "Incorrect old password")
    end
  end

  def unauthenticated(conn, _params) do
    Logger.info "Unauthorized login"
    error_msg(conn, 403, "Unauthorized")
  end

  def card_verification(conn, params) do
    if params["birthday"] == "" && params["cardnumber"] == "" do
        error_msg(conn, 400, "Birthday and cardnumber can't be blank!")
    else
      with {:ok, _date} <- UtilityContext.birth_date_transform(params["birthday"]),
        %Member{} <- MemberContext.card_number_verification(params["cardnumber"]),
        {:ok, member} <- MemberContext.member_card_verification(params),
        {:ok, member} <- UserContext.validate_registered_member(member.id)
      do
        render(conn, MemberLinkWeb.Api.V1.UserView, "user.json", member: member)
      else
        {:already_registered} ->
          error_msg(conn, 400, "Member is already registered")
        {:empty_birthday} ->
          error_msg(conn, 400, "Birthday can't be blank")
        {:invalid_datetime_format} ->
          error_msg(conn, 400, "Invalid Date format")
        {:cardnumber_is_invalid} ->
          error_msg(conn, 400, "Card number can't be blank")
        {:card_number_not_found} ->
          error_msg(conn, 400, "Member not found")
        {:inactive_member} ->
          error_msg(conn, 400, "Member is not Active")
        {:member_not_found} ->
          error_msg(conn, 400, "Member not found")
        _ ->
          error_msg(conn, 500, "Server error")
      end
    end
  end

  def register(conn, params) do
    member = MemberContext.get_member!(params["member_id"])
    params = Map.merge(params, %{
      "first_name" => member.first_name, "last_name" => member.last_name,
      "middle_name" => member.middle_name, "suffix" => member.suffix,
      "birthday" =>  member.birthdate, "gender" => member.gender,
      "verification_code" => UserContext.generate_verification_code()
    })
    case UserContext.register_member(member, params) do
      {:ok, user} ->
        UserContext.update_user_expiry(user)
        {:ok, user} = UserContext.register_update_member(user, %{
          "created_by_id" => user.id,
          "updated_by_id" => user.id
        })
        if not is_nil(user.mobile) do
          user_mobile = transforms_number(user.mobile)
        else
          user_mobile = transforms_number(user.other_mobile)
        end
        SMS.send(%{text: "Your verification code is #{user.verification_code}", to: user_mobile})
        _email =
          user
          |> EmailSmtp.invite_user()
          |> Mailer.deliver_now
        random = Ecto.UUID.generate
        secure_random = "#{user.id}+#{random}"
        new_conn = MemberLink.Guardian.Plug.sign_in(conn, secure_random)
        token = Plug.current_token(new_conn)

        claims = Plug.current_claims(new_conn)
        exp = Map.get(claims, "exp")
        new_conn
        |> put_resp_header("authorization", "Bearer #{token}")
        |> render(UserView, "login.json", user_id: user.id,
                  exp: exp, token: token, verified: user.verification)
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(ErrorView, "changeset_error_api.json", changeset: changeset)
    end
  end

  def sms_verification(conn, params) do
    user = MG.current_resource_api(conn)
    token = Plug.current_token(conn)
    claims = Plug.current_claims(conn)
    exp = Map.get(claims, "exp")
    if params["pin"] == nil || params["pin"] == "" || params == %{} do
      error_msg(conn, 400, "Invalid pin")
    else
      with true <- UserContext.check_pin_expiry(user),
           {:ok, "user"} <- UserContext.check_user_status(user.id),
           user = %User{} <- UserContext.validate_user_verification_code(
             user.id, params["pin"]),
           {:ok, user} <- UserContext.update_verification(
             user, %{verification: true})
      do
        conn
        |> render(UserView, "sms_verification.json", user: user, token: token, exp: exp)
      else
        false ->
          error_msg(conn, 404, "pin expired")
        {:locked} ->
          error_msg(conn, 400, "User is locked please reset your password")
        nil ->
          att =
            if is_nil(user.attempts) do
              1
            else
              if user.attempts < 3 do
                user.attempts + 1
              else
                user.attempts
              end
            end

            {:ok, user} = UserContext.update_user_attempts(user, %{attempts: att})

            error =
              if att == 3 do
                UserContext.update_user_status(user)
                "Your account has been locked, you are advised to reset your password."
              else
                "Invalid Pin"
              end

          error_msg(conn, 400, error)
        _ ->
          error_msg(conn, 500, "Server error")
      end
    end
  end

  def request_pin(conn, _params) do
    user = MG.current_resource_api(conn)
    {:ok, user} =
      user
      |> UserContext.delete_verification_code()
      |> UserContext.update_verification_code_member(
        %{"verification_code" => UserContext.generate_verification_code()})
    verified_false = %{verification: false}
    with {:ok, user} <- UserContext.update_verification(
          user, verified_false)
    do
      user = if Application.get_env(:member_link, :env) != :test do
        {:ok, user} = UserContext.update_user_expiry(user)
        if not is_nil(user.mobile) do
          user_mobile = transforms_number(user.mobile)
        else
          user_mobile = transforms_number(user.other_mobile)
        end
        SMS.send(%{text: "Your verification code is #{user.verification_code}", to: user_mobile})
        _email =
          user
          |> EmailSmtp.invite_user()
          |> Mailer.deliver_now
          user
      else
        user
      end
      conn
      |> put_status(200)
      |> render(UserView, "request_pin.json", message: "Successfully sent the PIN to the user's mobile number and email", code: 200, exp: user.verification_expiry)
    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(ErrorView, "changeset_error_api.json", changeset: changeset)
      _ ->
      error_msg(conn, 500, "Server error")
    end
  end

  def forgot_username(conn, params) do
    send_thru = params["recovery"]

    with {:ok, _email_validate} <- UserContext.validate_forgot_username(params)
    do
      cond do
        send_thru == "email" ->
          with {:ok, user} <- UserContext.username_get_user_email(params["text"]),
            {:ok, user} <- UserContext.validate_request(user)
          do
            _email =
              user
              |> EmailSmtp.forgot_username()
              |> Mailer.deliver_now
            conn
            |> put_status(200)
            |> render(UserView, "forgot_credential.json", message: "Successfully sent the username to the user's email", code: 200)
          else
            {:not_verified} ->
              error_msg(conn, 400, "user is not a registered member!")
            {:user_not_found} ->
              error_msg(conn, 404, "Email not found")
           _ ->
            error_msg(conn, 500, "Server error")
          end

        send_thru == "mobile" ->
        with {:ok, user} <- UserContext.username_get_user_mobile(params["text"]),
            {:ok, user} <- UserContext.validate_request(user)
        do
          if not is_nil(user.mobile) do
            user_mobile = transforms_number(user.mobile)
          else
            user_mobile = transforms_number(user.other_mobile)
          end
          SMS.send(%{text: "Your username is #{user.username}", to: user_mobile})
          conn
          |> put_status(200)
          |> render(UserView, "forgot_credential.json", message: "Successfully sent the username to the user's mobile number", code: 200)
          else
            {:not_verified} ->
              error_msg(conn, 400, "user is not a registered member!")
            {:user_not_found} ->
              error_msg(conn, 404, "Mobile not found")
          _ ->
            error_msg(conn, 500, "Server error")
        end
        true ->
          error_msg(conn, 404, "Recovery not found")
      end
    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(ErrorView, "changeset_error_api.json", changeset: changeset)
      {:recovery_not_found} ->
        error_msg(conn, 404, "Recovery not found")
    end
  end

  def forgot_password(conn, params) do
    send_thru = params["recovery"]

    with {:ok, _email_validate} <- UserContext.validate_forgot_password(params)
    do
     cond do
       send_thru == "email" ->
        with {:ok, user} <- UserContext.get_user_by_email(
            params["username"], params["text"]),
          %User{} <- UserContext.get_member_username(
            params["username"]),
          {:ok, user} <- UserContext.validate_request(user)
        do
          user
          |> UserContext.delete_verification_code()
          {:ok, user} = UserContext.update_verification_code_member(
            user, %{"verification_code" => UserContext.generate_verification_code()})
          UserContext.update_user_expiry(user)
          _email =
            user
            |> EmailSmtp.forgot_password()
            |> Mailer.deliver_now
          conn
          |> put_status(200)
          |> render(UserView, "forgot_credential_password.json", message: "Successfully sent the PIN to the user's email", code: 200, user: user)
        else
          {:inactive_member} ->
            error_msg(conn, 400, "The member you have entered is not active")
          {:not_verified} ->
            error_msg(conn, 400, "user is not a registered member!")
          {:not_found} ->
            error_msg(conn, 400, "username not found")
          {:user_not_found} ->
            error_msg(conn, 404, "User not found")
        _ ->
          error_msg(conn, 500, "Server error")
        end

      send_thru == "mobile" ->
        with {:ok, user} <- UserContext.get_user_by_mobile(
            params["username"], params["text"]),
          %User{} <- UserContext.get_member_username(
            params["username"]),
          {:ok, user} <- UserContext.validate_request(user)
        do
          user
          |> UserContext.delete_verification_code()
          {:ok, user} = UserContext.update_verification_code_member(
            user, %{"verification_code" => UserContext.generate_verification_code()})
          UserContext.update_user_expiry(user)
          if not is_nil(user.mobile) do
            user_mobile = transforms_number(user.mobile)
          else
            user_mobile = transforms_number(user.other_mobile)
          end
          SMS.send(%{text: "Your verification code for reset password is #{user.verification_code}", to: user_mobile})
          conn
          |> put_status(200)
          |> render(UserView, "forgot_credential_password.json",
                    message: "Successfully sent the PIN to the user's mobile number",
                    code: 200,
                    user: user
          )
        else
          {:inactive_member} ->
            error_msg(conn, 400, "The member you have entered is not active")
          {:not_verified} ->
            error_msg(conn, 400, "user is not a registered member!")
          {:not_found} ->
            error_msg(conn, 400, "username not found")
          {:user_not_found} ->
            error_msg(conn, 404, "User not found")
        _ ->
          error_msg(conn, 500, "Server error")
        end
       true ->
          error_msg(conn, 400, "recovery is invalid")
     end
    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(ErrorView, "changeset_error_api.json", changeset: changeset)
      {:recovery_not_found} ->
        error_msg(conn, 404, "Recovery not found")
    end
  end

  def resend_code_api(conn, params) do
    send_thru = params["recovery"]

    with {:ok, _email_validate} <- UserContext.validate_forgot_password(params)
    do
     cond do
       send_thru == "email" ->
        with {:ok, user} <- UserContext.get_user_by_email(
            params["username"], params["text"]),
          %User{} <- UserContext.get_member_username(
            params["username"]),
          {:ok, user} <- UserContext.validate_request(user)
        do
          user
          |> UserContext.delete_verification_code()
          {:ok, user} = UserContext.update_verification_code_member(
            user, %{"verification_code" => UserContext.generate_verification_code()})
          UserContext.update_user_expiry(user)
          _email =
            user
            |> EmailSmtp.forgot_password()
            |> Mailer.deliver_now
          conn
          |> put_status(200)
          |> render(UserView, "forgot_credential_password.json", message: "Successfully sent the PIN to the user's email", code: 200, user: user)
        else
          {:inactive_member} ->
            error_msg(conn, 400, "The member you have entered is not active")
          {:not_verified} ->
            error_msg(conn, 400, "user is not a registered member!")
          {:not_found} ->
            error_msg(conn, 400, "username not found")
          {:user_not_found} ->
            error_msg(conn, 404, "User not found")
        _ ->
          error_msg(conn, 500, "Server error")
        end

      send_thru == "mobile" ->
        with {:ok, user} <- UserContext.get_user_by_mobile(
            params["username"], params["text"]),
          %User{} <- UserContext.get_member_username(
            params["username"]),
          {:ok, user} <- UserContext.validate_request(user)
        do
          user
          |> UserContext.delete_verification_code()
          {:ok, user} = UserContext.update_verification_code_member(
            user, %{"verification_code" => UserContext.generate_verification_code()})
          UserContext.update_user_expiry(user)
          if not is_nil(user.mobile) do
            user_mobile = transforms_number(user.mobile)
          else
            user_mobile = transforms_number(user.other_mobile)
          end
          SMS.send(%{text: "Your verification code for reset password is #{user.verification_code}", to: user_mobile})
          conn
          |> put_status(200)
          |> render(UserView, "forgot_credential_password.json",
                    message: "Successfully sent the PIN to the user's mobile number",
                    code: 200,
                    user: user
          )
        else
          {:inactive_member} ->
            error_msg(conn, 400, "The member you have entered is not active")
          {:not_verified} ->
            error_msg(conn, 400, "user is not a registered member!")
          {:not_found} ->
            error_msg(conn, 400, "username not found")
          {:user_not_found} ->
            error_msg(conn, 404, "User not found")
        _ ->
          error_msg(conn, 500, "Server error")
        end
       true ->
          error_msg(conn, 400, "recovery is invalid")
     end
    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(ErrorView, "changeset_error_api.json", changeset: changeset)
      {:recovery_not_found} ->
        error_msg(conn, 404, "Recovery not found")
    end
  end

  def forgot_password_confirm(conn, %{"user_id" => id, "verification_code" => pin}) do
    cond do
      id == "" && pin == "" ->
        error_msg(conn, 400, "user id and verification code can't be blank")
      id == "" ->
        error_msg(conn, 400, "user id can't be blank")
      pin == "" ->
        error_msg(conn, 400, "verification code can't be blank")
      true ->
        with user = %User{} <- UserContext.get_user_memberlink(id),
             {:ok, user} <- UserContext.validate_request(user),
             true <- UserContext.check_pin_expiry_forgot(user),
             %User{} <- UserContext.validate_user_verification_code(id, pin),
             {:ok, user} <- UserContext.update_verification(
               user, %{verification: false})
        do
          conn
          |> render(UserView, "forgot_password_confirm.json",
                    user: user, message: "Valid verification code", code: 200)
        else
          false ->
            error_msg(conn, 400, "pin expired")
          {:not_verified} ->
            error_msg(conn, 400, "user is not a registered member!")
          {:locked} ->
            error_msg(conn, 404, "User is locked please reset your password")
          nil ->
            error_msg(conn, 400, "Invalid pin")
          {:user_not_found} ->
            error_msg(conn, 404, "User not found")
          _ ->
            error_msg(conn, 500, "Server error")
        end
    end
  end

  def forgot_password_reset(conn, params) do
    if params["user_id"] == "" do
      error_msg(conn, 400, "User id can't be blank")
    else
        with user = %User{} <- UserContext.get_user_memberlink(params["user_id"]),
            {:ok, user} <- UserContext.validate_request(user),
            {:ok, user} <- UserContext.reset_password_memberlink(user, params),
            {:ok, user} <- UserContext.attempts_reset(user, %{attempts: nil}),
            {:ok, user} <- UserContext.update_user_status_active(user)
        do
          Logger.info "User " <> user.username <> " just logged in"
          random = Ecto.UUID.generate
          secure_random = "#{user.id}+#{random}"
          new_conn = MemberLink.Guardian.Plug.sign_in(conn, secure_random)
          token = Plug.current_token(new_conn)

          claims = Plug.current_claims(new_conn)
          exp = Map.get(claims, "exp")
          new_conn
          |> put_status(200)
          |> put_resp_header("authorization", "Bearer #{token}")
          |> render(UserView, "login.json",
                    user_id: user.id,
                    token: token,
                    exp: exp,
                    verified: user.verification
          )
        else
          {:not_verified} ->
            error_msg(conn, 400, "user is not a registered member!")
          {:old_password} ->
            error_msg(conn, 400, "Cannot use old password")
          {:user_not_found} ->
            error_msg(conn, 404, "User not found")
          {:error, changeset} ->
            conn
            |> put_status(400)
            |> render(ErrorView, "changeset_error_api.json", changeset: changeset)
          _ ->
            error_msg(conn, 500, "Server error")
        end
    end
  end

  defp error_msg(conn, status, message) do
    conn
    |> put_status(status)
    |> render(ErrorView, "error.json", message: message, code: status)
  end

  # defp changeset_error_msg(conn, status, message) do
  #   conn
  #   |> put_status(status)
  #   |> render(ErrorView, "changeset_error.json", message: message, code: status)
  # end

  defp transforms_number(number) do
    number =
      number
      |> String.slice(1..11)
    "63#{number}"
  end

end
