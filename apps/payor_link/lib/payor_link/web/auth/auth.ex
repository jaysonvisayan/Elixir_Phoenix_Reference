defmodule Innerpeace.Auth do
  @moduledoc false

  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  alias Innerpeace.Db.Base.{
    UserContext,
    Api.UtilityContext,
    AuthContext,
  }

  def username_and_pass(conn, username, given_pass) do
    with false <- UtilityContext.validate_string(username) do
      user = UserContext.get_username(username)
      if is_nil(user) || is_nil(user.hashed_password) do
        dummy_checkpw
        {:error, :not_found, conn}
      else
        cond do
          user && checkpw(given_pass, user.hashed_password) ->
            {:ok, login(conn, user)}
          user ->
            {:error, :unauthorized, conn}
          true ->
            dummy_checkpw()
            {:error, :not_found, conn}
        end
      end
    else
      _ ->
      {:error, :invalid_username, conn}
    end
  end

  def username_and_pass(conn, username, given_pass, payroll_code) do
    with false <- UtilityContext.validate_string(username) do
      user = UserContext.get_username(username)
      user = if is_nil(user) do UserContext.get_user_by_email(username) else user end
      user = if is_nil(user) do UserContext.get_user_by_mobile(username) else user end
      if is_nil(user) || is_nil(user.hashed_password) do
        dummy_checkpw
        {:error, :not_found, conn}
      else
        cond do
          user && checkpw(given_pass, user.hashed_password) && user.payroll_code == payroll_code ->
            {:ok, login(conn, user)}
          user ->
            {:error, :unauthorized, conn}
          true ->
            dummy_checkpw()
            {:error, :not_found, conn}
        end
      end
    else
      _ ->
      {:error, :invalid_username, conn}
    end
  end

  def verify_password(user, current_password) do
    with true <- not is_nil(user.hashed_password),
         true <- user && checkpw(current_password, user.hashed_password) do
           {:password_correct}
    else
      _ ->
        {:error_user, "Invalid current password"}
         end
  end

  def check_user_history([], password), do: {:not_in_history}
  def check_user_history([head | tails], password) do
    check_validity(
      checkpw(password, head),
      password,
      tails
    )
  end

  def check_validity(result, password, tails) when result == true, do: {:in_history}
  def check_validity(result, password, tails) when result == false, do: check_user_history(tails, password)

  def login(conn, user) do
    role = UserContext.first_role(user)
    permissions = AuthContext.get_permissions(role)

    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    [id, random] = String.split(secure_random, "+")

    conn
    |> add_random_cookie(random)
    |> PayorLink.Guardian.Plug.sign_in(secure_random, pem: permissions)
  end

  def logout(conn) do
    conn
    |> Plug.Conn.delete_resp_cookie("nova", [
        secure: get_secure_by_env(),
        http_only: true,
        domain: conn.host
      ])
    |> PayorLink.Guardian.Plug.sign_out
    |> Plug.Conn.configure_session(drop: true)
    |> Plug.Conn.clear_session
  end

  defp add_random_cookie(conn, random) do
    random
    |> encrypt256
    |> store_cookie(conn)
  end

  defp encrypt256(value) do
    :sha256
    |> :crypto.hash(value)
    |> Base.encode16()
  end

  defp store_cookie(value, conn) do
    conn
    |> Plug.Conn.put_resp_cookie("nova", value, [
        secure: get_secure_by_env(),
        http_only: true,
        domain: conn.host
      ])
  end

  defp get_secure_by_env do
    case Application.get_env(:payor_link, :env) do
      :prod ->
        true
       _ ->
        false
    end
  end
end
