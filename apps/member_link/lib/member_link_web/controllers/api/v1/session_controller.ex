defmodule MemberLinkWeb.Api.V1.SessionController do
  use MemberLinkWeb, :controller
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  import Logger

  alias MemberLink.Guardian.Plug
  alias Innerpeace.Db.Utilities.SMS
  alias Innerpeace.Db.Schemas.{
    User
  }
  alias Innerpeace.Db.Base.{
    UserContext,
    MemberContext
  }

  alias Innerpeace.MemberLink.{
    EmailSmtp,
    Mailer
  }

  def login(conn, params) do
    username = params["username"]
    password = params["password"]

    with user = %User{} <- UserContext.get_member_username(username),
         false <- is_nil(user.hashed_password),
         true <- user && checkpw(password, user.hashed_password),
         false <- is_nil(user.member_id)
    do
      verified =
        if user.verification == true do
          true
        else
          false
        end
      user =
        if user.verification == true do
          user
        else
          UserContext.delete_verification_code(user)
          params = %{"verification_code" => UserContext.generate_verification_code()}

          with {:ok, user} <- UserContext.update_verification_code_member(user, params)
          do
            if Application.get_env(:member_link, :env) != :test do
              UserContext.update_user_expiry(user)
              user_mobile = transforms_number(user.mobile)
              SMS.send(%{text: "Your verification code is #{user.verification_code}", to: user_mobile})
              _email =
                user
                |> EmailSmtp.invite_user()
                |> Mailer.deliver_now
             user
            end
            user
          else
            {:error, changeset} ->
              error_msg(conn, 500, "Server error")
          end
        end
      if user.status == "locked" do
        error_msg(conn, 400, "Your Account is Locked Please Reset your Password")
      else
      Logger.info "User " <> username <> " just logged in"
      random = Ecto.UUID.generate
      secure_random = "#{user.id}+#{random}"
      new_conn = Plug.sign_in(conn, secure_random)
      token = Plug.current_token(new_conn)

      claims = Plug.current_claims(new_conn)
      exp = Map.get(claims, "exp")
      UserContext.attempts_reset(user, %{attempts: nil})

      new_conn
      |> put_resp_header("authorization", "Bearer #{token}")
      |> render(MemberLinkWeb.Api.V1.UserView, "login.json", user_id: user.id,
                token: token, exp: exp, verified: verified)
      end
      else
      {:not_found} ->
        dummy_checkpw()
        error_msg(conn, 404, "User not found")
      {:inactive_member} ->
        error_msg(conn, 400, "The Member you have entered is not Active")
      nil ->
        dummy_checkpw()
        error_msg(conn, 404, "User not found")
      true ->
        error_msg(conn, 400, "Wrong username and password")
      false ->
        user = UserContext.get_member_username(username)

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
            "Wrong username and password"
          end

        error_msg(conn, 400, error)
      _ ->
        error_msg(conn, 500, "Server error")
    end
  end

  def login_card(conn, params) do
    if Enum.all?([is_nil(params["username"]), is_nil(params["card_no"]), params == %{}]) do
      error_msg(conn, 400, "No Parameters found")
    else
      cond do
        Enum.any?([params["username"] == "" , params["card_no"] == ""]) ->
          error_msg(conn, 400, "Username or Card No can't be blank")
        Enum.all?([not is_nil(params["username"]), not is_nil(params["card_no"])]) ->
          with user = %User{} <- UserContext.get_member_username(params["username"]),
               {:ok, member} <- MemberContext.get_member_by_card_no_memberlink(params["card_no"]),
               {:ok, member_id} <- UserContext.login_by_username_and_card_no(user, member.id)
          do
            username = params["username"]
            Logger.info "User " <> username <> " just logged in"
            random = Ecto.UUID.generate
            secure_random = "#{user.id}+#{random}"
            new_conn = Plug.sign_in(conn, secure_random)
            token = Plug.current_token(new_conn)

            claims = Plug.current_claims(new_conn)
            exp = Map.get(claims, "exp")
            UserContext.attempts_reset(user, %{attempts: nil})

            new_conn
            |> put_resp_header("authorization", "Bearer #{token}")
            |> render(MemberLinkWeb.Api.V1.UserView, "login_card.json", user_id: user.id,
                token: token, exp: exp, verified: user.verification, member_id: member_id)
          else
            {:not_found} ->
              error_msg(conn, 400, "User not found")
            nil ->
              error_msg(conn, 400, "User not found")
            {:inactive_member} ->
              error_msg(conn, 400, "The Member you have entered is not Active")
          end
        not is_nil(params["username"]) ->
          with user = %User{} <- UserContext.get_member_username(params["username"]) do
            member_id = user.member_id
            username = params["username"]
            Logger.info "User " <> username <> " just logged in"
            random = Ecto.UUID.generate
            secure_random = "#{user.id}+#{random}"
            new_conn = Plug.sign_in(conn, secure_random)
            token = Plug.current_token(new_conn)

            claims = Plug.current_claims(new_conn)
            exp = Map.get(claims, "exp")
            UserContext.attempts_reset(user, %{attempts: nil})

            new_conn
            |> put_resp_header("authorization", "Bearer #{token}")
            |> render(MemberLinkWeb.Api.V1.UserView, "login_card.json", user_id: user.id,
                token: token, exp: exp, verified: user.verification, member_id: member_id)
          else
            {:not_found} ->
              error_msg(conn, 404, "User not found")
            {:inactive_member} ->
              error_msg(conn, 400, "The Member you have entered is not Active")
          end
        not is_nil(params["card_no"]) ->
          with {:ok, member} <- MemberContext.get_member_by_card_no_memberlink(params["card_no"]) do
            user = member.user
            Logger.info "User " <> user.username <> " just logged in"
            random = Ecto.UUID.generate
            secure_random = "#{user.id}+#{random}"
            new_conn = Plug.sign_in(conn, secure_random)
            token = Plug.current_token(new_conn)

            claims = Plug.current_claims(new_conn)
            exp = Map.get(claims, "exp")
            UserContext.attempts_reset(user, %{attempts: nil})

            new_conn
            |> put_resp_header("authorization", "Bearer #{token}")
            |> render(MemberLinkWeb.Api.V1.UserView, "login_card.json", user_id: user.id,
                token: token, exp: exp, verified: user.verification, member_id: member.id)
          else
            nil ->
              error_msg(conn, 404, "User not found")
            {:not_found} ->
              error_msg(conn, 404, "User not found")
          end
        true ->
          error_msg(conn, 500, "Can't be blank")
      end
    end
  end

  def login_new(conn, user) do
    conn
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    Plug.sign_in(conn, secure_random)
  end

  def unauthenticated(conn, _params) do
    Logger.info "Unauthorized login"
    error_msg(conn, 403, "Unauthorized")
  end

  defp transforms_number(number) do
    number =
      number
      |> String.slice(1..11)
    "63#{number}"
  end

  defp error_msg(conn, status, message) do
    conn
    |> put_status(status)
    |> render(MemberLinkWeb.Api.ErrorView, "error.json",
              message: message, code: status)
  end

  def change_password(conn, params) do
    with {:valid_parameter} <- validate_cp_params(params) do
      change_password_level2(conn, params)
    else
      _ ->
        change_password_return(conn, {404, "false", "Invalid Parameter"})
    end
  end

  defp validate_cp_params(params) do
    keys = Map.keys(params)
    valid_keys = ["password", "username"]

    result = keys -- valid_keys
    validate_cp_params_return(result)
  end

  defp validate_cp_params_return([]), do: {:valid_parameter}
  defp validate_cp_params_return(params), do: {:invalid_parameter}

  defp change_password_level2(conn,
    %{
      "username" => username,
      "password" => password
    }
  ) do
    result =
      with user = %User{} <- UserContext.get_member_username(username),
          {:valid_hashed_password} <- user_hashed_password(user.hashed_password),
          {:valid_user_member} <- valid_user_member(user.member_id),
          {:valid_new_password} <- validate_new_password(password)
      do
        UserContext.update_password(user, %{password: password, password_confirmation: password})

        {200, "true", "User's password has been updated"}
      else
        {:not_found} ->
          dummy_checkpw()
          {404, "false", "User not found"}
        {:inactive_member} ->
          {400, "false", "User is not active"}
        {:user_not_found} ->
          dummy_checkpw()
          {404, "false", "User not found"}
        {:invalid_hashed_password} ->
          {404, "false", "User has no password saved"}
        {:invalid_user_member} ->
          {400, "false", "User is not eligible for MemberLink"}
        {:invalid_new_password} ->
          # temporarily relax validation
          # {400, "false", "Password must be 8 to 20 characters long and should include at least 1 numeric character, special character and uppercase letter"}
          {400, "false", "Password must be 8 characters and contains lower case, upper case and special characters"}
        false ->
          {400, "false", "Wrong username and password"}
        _ ->
          {404, "false", "Server Error"}
      end

    change_password_return(conn, result)
  end

  defp user_hashed_password(value) when not is_nil(value), do: {:valid_hashed_password}
  defp user_hashed_password(value) when is_nil(value), do: {:invalid_hashed_password}

  defp valid_old_password(user, old_password) do
    result = user && checkpw(old_password, user.hashed_password)

    valid_old_password_return(result)
  end

  defp valid_old_password_return(value) when value == true, do: {:valid_old_password}
  defp valid_old_password_return(value) when value == false, do: {:invalid_old_password}
  defp valid_old_password_return(value) when is_nil(value), do: {:user_not_found}

  defp valid_user_member(value) when not is_nil(value), do: {:valid_user_member}
  defp valid_user_member(value) when is_nil(value), do: {:invalid_user_member}

  defp validate_new_password(new_password) do
    # temporarily relax validation
    # result = Regex.match?(~r/(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,}/, new_password)
    result = Regex.match?(~r/(?=^.{8,}$)((?=.*\d)|(?=.*\W+))(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$/, new_password)

    new_password_return(result)
  end

  defp new_password_return(result) when result == true, do: {:valid_new_password}
  defp new_password_return(result) when result == false, do: {:invalid_new_password}

  defp change_password_return(conn, result) do
    {status, is_success, remarks} = result

    conn
    |> put_status(status)
    |> render(
      MemberLinkWeb.Api.V1.UserView,
      "change_password_return.json",
      remarks: remarks,
      is_success: is_success
    )
  end
end
