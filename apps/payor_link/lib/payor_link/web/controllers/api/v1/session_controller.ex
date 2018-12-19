defmodule Innerpeace.PayorLink.Web.Api.V1.SessionController do
  use Innerpeace.PayorLink.Web, :controller
  use Ecto.Schema

  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  import Ecto.Changeset
  import Logger

  alias Innerpeace.Db.Base.UserContext
  alias Innerpeace.Db.Schemas.User
  alias PayorLink.Guardian.Plug

  def login(conn, params) do
    with true <- UserContext.validate_login_params(params) do
      username_and_pass(conn, params["username"], params["password"])
    else
      _ ->
        error_msg(conn, 403, "Invalid Parameters! 'username' and 'password' are the only parameters allowed.")
    end
  end

  defp username_and_pass(conn, username, given_pass) do
    with user = %User{} <- UserContext.get_username(username),
         false <- is_nil(user.hashed_password),
         true <- user && checkpw(given_pass, user.hashed_password)
    do
      Logger.info "User " <> username <> " just logged in"

      random = Ecto.UUID.generate
      secure_random = "#{user.id}+#{random}"
      new_conn = Plug.sign_in(conn, secure_random)
      jwt = Plug.current_token(new_conn)

      claims = Plug.current_claims(new_conn)
      _exp = Map.get(claims, "exp")

      new_conn
      |> put_resp_header("authorization", "Bearer #{jwt}")
      |> render(Innerpeace.PayorLink.Web.Api.UserView, "login.json", user_id: user.id, jwt: jwt)
    else
      nil ->
        dummy_checkpw()
        error_msg(conn, 404, "Not Found!")
      true ->
        error_msg(conn, 403, "Unauthorized user")
      false ->
        error_msg(conn, 403, "Invalid Login! Please try again.")
    end
  end

  def logout(conn, _params) do
    with  jwt <- Plug.current_token(conn),
          claims <- Plug.current_claims(conn),
          {:ok, _a} <- PayorLink.Guardian.revoke(jwt, claims)
     do
      conn
      |> put_status(200)
      |> render(Innerpeace.PayorLink.Web.Api.UserView, "logout.json", status: "signed out!")
     else
       nil ->
         error_msg(conn, 404, "No session found!")
       {:error, _error} ->
         error_msg(conn, 404, "Invalid token!")
       {:error, :no_session} ->
         error_msg(conn, 404, "No session found!")
       {:error, :token_not_found} ->
         error_msg(conn, 404, "Invalid token!")
    end
  end

  def unauthenticated(conn, _params) do
    Logger.info "Unauthorized login"
    error_msg(conn, 403, "Unauthorized")
  end

  defp error_msg(conn, status, message) do
    conn
    |> put_status(status)
    |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: message)
  end
end
