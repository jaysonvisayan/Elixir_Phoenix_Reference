defmodule AccountLinkWeb.UserController do
  use AccountLinkWeb, :controller

  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  alias AccountLinkWeb.ErrorView
  alias AccountLinkWeb.Auth
  alias Innerpeace.Db.Base.{
    UserContext,
    AccountContext
  }
  alias Innerpeace.Db.Schemas.User

  def register(conn, %{"id" => account_group_id}) do
    account_group = AccountContext.get_account_group(account_group_id)
    render conn, "register.html", account_group: account_group
  end

  def user_validate(conn, _params) do
    users = UserContext.select_user_fields()
    json conn, Poison.encode!(users)
  end

  def sign_up(conn, %{"id" => account_group_id, "user" => params}) do
    account_group = AccountContext.get_account_group(account_group_id)

    mobile = params["mobile"]
    mobile = if is_nil(mobile) == false do
      String.replace(mobile, "-", "")
    end
    tel_no = params["tel_no"]
    tel_no = if is_nil(tel_no) == false do
      String.replace(tel_no, "-", "")
    end

    params = Map.merge(params, %{"mobile" => mobile, "tel_no" => tel_no})

    with {:ok, user} <- UserContext.create_user_accountlink(params)
    do
      user_params = %{
        "created_by_id" => user.id,
        "updated_by_id" => user.id
      }

      with {:ok, user} <- UserContext.update_user_accountlink(user, user_params)
      do
        user_account_params = %{
          "user_id" => user.id,
          "account_group_id" => account_group_id,
          "role" => params["role"]
        }

        with {:ok, _user} <- UserContext.create_user_account(user_account_params)
        do
          conn
          |> render("register.html", modal_open: true, account_group: account_group)
        end
      end
    else
      {:error, changeset} ->
        error = ErrorView.translate_errors(changeset)

        conn
        |> put_flash(:error, error)
        |> render("register.html", account_group: account_group)
      _ ->
        conn
        |> put_flash(:error, "Error in User Registration")
        |> render("register.html", account_group: account_group)
    end
  end

  def change_password(conn, params) do
    render(conn, "change_password.html", locale: conn.assigns.locale)
  end

  def update_change_password(conn, %{"user" => user_params}) do
    password = user_params["password"]
    user = conn.assigns.current_user
    changeset = User.password_changeset(user, user_params)

    if checkpw(user_params["old_password"], user.hashed_password) do
      if user_params["password"] == user_params["password_confirmation"] do
        if user_params["old_password"] == user_params["password"] do
          conn
          |> put_flash(:error, "Cannot use old password")
          |> render("change_password.html")
        else
          case UserContext.update_password(changeset) do
            {:ok, user} ->
              {:ok, user} = UserContext.update_user_status_active(user)
              {:ok, user} = UserContext.update_user_attempts(user, %{attempts: 0})
              conn
              |> Auth.login(user)
              |> put_flash(:info, "Password changed successful.")
              |> redirect(to: member_path(conn, :index, conn.assigns.locale))
            {:error, changeset} ->
              conn
              |> put_flash(:error, "Password must be at least 8 characters long and must contain at least one lower case character, one upper case character, and one special character(!@#$)")
              |> render("change_password.html", changeset: changeset, user: user,
                        action: session_path(conn, :update_change_password,
                                             conn.assigns.locale))
          end
          end
      else
        conn
        |> put_flash(:error, "Password and Password Confirmation doesn't match")
        |> render("change_password.html")
        end
    else
      conn
      |> put_flash(:error, "Old Password did not match")
      |> render("change_password.html")
    end
  end

end
