defmodule RegistrationLinkWeb.SessionController do
  use RegistrationLinkWeb, :controller
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  alias RegistrationLinkWeb.Auth
  # alias Innerpeace.Db.Utilities.SMS
  alias Innerpeace.Db.Base.{
    UserContext
  }
  alias Innerpeace.Db.Repo
  import Ecto.Query
  alias Innerpeace.Db.Schemas.{
    User,
    UserRole,
    Role,
    RolePermission,
    Permission,
    RoleApplication,
    Application
  }


  def sign_in(conn, _) do
    render conn, "sign_in.html"
  end

  def login(conn, %{"session" => user_params}) do
    username = user_params["username"]
    password = user_params["password"]

    with user = %User{} <- UserContext.get_user_by_uem(username),
         false <- is_nil(user.hashed_password),
         true <- user && checkpw(password, user.hashed_password)
    do
      if user.status == "locked" do
        conn
        |> put_flash(:error, "Your account has been locked, you are advised to reset your password.")
        |> render("sign_in.html")
      else
        conn = Auth.login(conn, user)
        _user = conn.private[:guardian_default_resource]
        conn
        |> set_application(user)
        |> put_flash(:info, "You’re now signed in!")
        |> set_permissions(user)
        |> redirect(to: batch_path(conn, :index))
      end
    else
      nil ->
        dummy_checkpw()
        conn
        |> put_flash(:error, "Invalid User!")
        |> render("sign_in.html")
      true ->
        conn
        |> put_flash(:error, "Invalid Login! Please try again.")
        |> render("sign_in.html")
      false ->
        error = "Invalid Login! Please try again."
        conn
        |> put_flash(:error, error)
        |> render("sign_in.html")
      _ ->
        conn
        |> put_flash(:error, "Error in user login. Please try again.")
        |> render("sign_in.html")
    end
  end


  def logout(conn, _) do
    conn
    |> Auth.logout
    |> put_flash(:info, "See you later!")
    |> redirect(to: session_path(conn, :sign_in))
  end

  defp set_application(conn, user) do
    query = (
      from ur in UserRole,
      join: r in Role, on: ur.role_id == r.id,
      join: ra in RoleApplication, on: r.id == ra.role_id,
      join: a in Application, on: ra.application_id == a.id,
      where: ur.user_id == ^user.id,
      select: a.name
    )
    application = query
                  |> Repo.all()
                  |> Enum.uniq()
    required_application = %{application: ["RegistrationLink"]}
    conn
    |> put_session(:applications, application)
    |> RegistrationLinkWeb.Authorize.can_access_application?(required_application)
  end

  defp set_permissions(conn, user) do
    query = (
      from ur in UserRole,
      join: r in Role, on: ur.role_id == r.id,
      join: pr in RolePermission, on: r.id == pr.role_id,
      join: p in Permission, on: pr.permission_id == p.id,
      where: ur.user_id == ^user.id,
      select: p.keyword
    )
    permissions = Innerpeace.Db.Repo.all(query)
    conn
    |> put_session(:permissions, permissions)
  end

end
