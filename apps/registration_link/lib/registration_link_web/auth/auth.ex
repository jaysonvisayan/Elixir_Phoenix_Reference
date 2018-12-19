defmodule RegistrationLinkWeb.Auth do
  @moduledoc false

  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Base.UserContext

  def username_and_pass(conn, username, given_pass) do
    user = UserContext.get_username(username)
    if is_nil(user) || is_nil(user.hashed_password) do
      dummy_checkpw()
      {:error, :not_found, conn}
    else
      cond do
        user && checkpw(given_pass, user.hashed_password) ->
          user = Repo.preload(user, :user_account)
          {:ok, login(conn, user)}
        user ->
          {:error, :unauthorized, conn}
        true ->
          dummy_checkpw()
          {:error, :not_found, conn}
      end
    end
  end

  def login(conn, user) do
    conn
    |> RegistrationLink.Guardian.Plug.sign_in(user)
  end

  def logout(conn) do
    RegistrationLink.Guardian.Plug.sign_out(conn)
  end
end
