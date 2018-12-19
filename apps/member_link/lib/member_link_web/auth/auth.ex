defmodule MemberLinkWeb.Auth do
  @moduledoc false

  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Base.UserContext

  def username_and_pass(conn, username, given_pass) do
    user = UserContext.get_username(username)
    user = if is_nil(user) do UserContext.get_user_by_email(username) else user end
    user = if is_nil(user) do UserContext.get_user_by_mobile(username) else user end
    if is_nil(user) || is_nil(user.hashed_password) do
      dummy_checkpw
      {:error, :not_found, conn}
    else
      cond do
        user && checkpw(given_pass, user.hashed_password) ->
          user = Repo.preload(user, :user_account)
          {:ok, login(conn, user)}
        user ->
          {:error, :unauthorized, conn}
        true ->
          dummy_checkpw
          {:error, :not_found, conn}
      end
    end
  end

  def login(conn, user) do
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    [id, random] = String.split(secure_random, "+")

    conn
    |> add_random_cookie(random)
    |> MemberLink.Guardian.Plug.sign_in(secure_random)
  end

  def logout(conn) do
    conn
    |> Plug.Conn.delete_resp_cookie("nova", [
        secure: get_secure_by_env(),
        http_only: true,
        domain: conn.host
      ])
    |> MemberLink.Guardian.Plug.sign_out
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
    case Application.get_env(:member_link, :env) do
      :prod ->
        true
       _ ->
        false
    end
  end
end
