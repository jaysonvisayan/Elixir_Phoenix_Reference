defmodule Innerpeace.PayorLink.Web.UserController do
  use Innerpeace.PayorLink.Web, :controller
  use Innerpeace.Db.PayorRepo, :context

  alias Innerpeace.Db.Schemas.{
    User,
    UserRole
  }

  alias Innerpeace.Db.Base.{
    UserContext
  }

  alias Innerpeace.PayorLink.{
    EmailSmtp,
    Mailer
  }

  alias Innerpeace.Auth
  alias Innerpeace.PayorLink.Web.Endpoint

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{users: [:manage_users]},
       %{users: [:access_users]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{users: [:manage_users]},
     ]] when not action in [
       :index,
       :show
     ]

  plug :valid_uuid?, %{origin: "users"}
  when not action in [:index]

  def index(conn, _params) do
    users = list_users()
    render(conn, "index.html", users: users)
  end

  def new(conn, _params) do
    changeset = User.changeset(%User{})
    render(conn, "step1.html", changeset: changeset)
  end

  def create_basic(conn, %{"user" => user_params}) do
    user_params =
      user_params
      |> Map.put("step", 2)
      |> Map.put("created_by_id", conn.assigns.current_user.id)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    case create_user(user_params) do
      {:ok, user} ->
        conn
        |> redirect(to: "/users/#{user.id}/setup?step=2")
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error creating user! Please check the errors below.")
        |> render("step1.html", changeset: changeset)
    end
  end

  def setup(conn, %{"id" => id, "step" => step}) do
    with {:ok, user} <- validate_user(get_user!(id)),
         {:ok, user} <- validate_step(user, user.step, String.to_integer(step))
    do
      go_to_step(conn, user, step)
    else
      {:not_allowed} ->
        not_allowed(conn)
      _ ->
        page_not_found(conn)
    end
  rescue
    _ ->
      page_not_found(conn)
  end
  def setup(conn, _), do: page_not_found(conn)

  defp validate_user(nil), do: nil
  defp validate_user(user), do: {:ok, user}

  def validate_step(_, user_step, step) when user_step < step, do: {:not_allowed}
  def validate_step(user, _, _), do: {:ok, user}

  defp go_to_step(conn, user, "1"), do: step1(conn, user)
  defp go_to_step(conn, user, "2"), do: step2(conn, user)
  defp go_to_step(conn, user, "3"), do: step3(conn, user)
  defp go_to_step(conn, _, _), do: page_not_found(conn)

  def update_setup(conn, %{"id" => id, "step" => step, "user" => user_params}) do
    user = get_user!(id)
    case step do
      "1" ->
        step1_update(conn, user, user_params)
      "2" ->
        step2_update(conn, user, user_params)
      "3" ->
        step3_update(conn, user)
    end
  end

  def step1(conn, user) do
    changeset = change_user(user)
    render(conn, "step1_edit.html", user: user, changeset: changeset)
  end

  def step1_update(conn, user, user_params) do
    user_params =
      user_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    case update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: "/users/#{user.id}/setup?step=2")
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error creating user! Please check the errors below.")
        |> render("step1_edit.html", user: user, changeset: changeset)
    end
  end

  def step2(conn, user) do
    changeset = UserRole.changeset(%UserRole{})
    applications = get_all_applications()
    render(conn, "step2.html", changeset: changeset, applications: applications, user: user)
  end

  def step2_update(conn, user, user_params) do
    if user_params["roles"] do
      if user.step == 4 do
        clear_user_roles(user.id)
        set_user_roles(user.id, user_params["roles"])
        update_user(user, %{"updated_by_id" => conn.assigns.current_user.id})
        conn
        |> put_flash(:info, "Successfully updated user roles!")
        |> redirect(to: "/users/#{user.id}/setup?step=3")
      else
        clear_user_roles(user.id)
        set_user_roles(user.id, user_params["roles"])
        update_user(user, %{"step" => 3, "updated_by_id" => conn.assigns.current_user.id})
        conn
        |> put_flash(:info, "Successfully added user roles!")
        |> redirect(to: "/users/#{user.id}/setup?step=3")
      end
    else
      conn
      |> put_flash(:error, "Please select at least one role!")
      |> redirect(to: "/users/#{user.id}/setup?step=2")
    end
  end

  def step3(conn, user) do
    changeset = change_user(user)
    render(conn, "step3.html", user: user, changeset: changeset)
  end

  def step3_update(conn, user) do
    user = get_user!(user.id)
    if user.step == 4 do
      conn
      |> put_flash(:info, "User updated successfully!")
      |> redirect(to: user_path(conn, :index))
    else
      {:ok, user} = update_user(user, %{step: 4})
      if user.password_token do

        url =
          if Application.get_env(:payor_link, :env) == :prod do
             Atom.to_string(conn.scheme) <> "://"
                  <> Endpoint.struct_url.host
          else
              Endpoint.url
          end

        user =
          user
          |> Map.put(:link, "#{url}/create?password_token=")

        user |> EmailSmtp.invite_user() |> Mailer.deliver_now()
      end
      conn
      |> put_flash(:info, "User created successfully! Please check email for password creation")
      |> redirect(to: user_path(conn, :index))
    end
  end

  def show(conn, %{"id" => id}) do
    user = get_user!(id)

    if is_nil(user) do
      conn
      |> put_flash(:error, "Invalid User!")
      |> redirect(to: user_path(conn, :index))
    else
      render(conn, "show.html", user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = get_user!(id)
    {:ok, _user} = delete_user(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: user_path(conn, :index))
  end

  def user_validate(conn, _params) do
    users = select_user_fields()
    json conn, Poison.encode!(users)
  end

  def submit_change_password(conn, %{"id" => id, "user" => params})do
    user =
      id
      |> UserContext.get_user!()

    params =
      params
      |> Map.put("attempt", 0)
      |> Map.put("status", "active")

    changeset =
      %User{}
      |> User.password_changeset()

    common_password = UserContext.get_all_common_password()
    password_history = UserContext.get_all_user_password(id)

    with {:password_correct} <- Auth.verify_password(user, params["current_password"]),
         true <- not Enum.member?(common_password, params["password"]),
         {:not_in_history} <- Auth.check_user_history(password_history, params["password"]),
         {:ok, user} <- UserContext.update_password(user, params),
         {:ok}  <- UserContext.insert_password_history(user, params)
    do
      conn
      |> put_flash(:info, "Updating password successful")
      |> render(
        "change_password.html",
        changeset: changeset,
        user: user
      )
    else
      false ->
        conn
        |> put_flash(:error, "The password you enter belongs to the database common password.")
        |> render(
          "change_password.html",
          changeset: changeset,
          user: user
        )
      {:error_user, message} ->
        conn
        |> put_flash(:error, message)
        |> render(
          "change_password.html",
          changeset: changeset,
          user: user
        )
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Pleae check you errors")
        |> render(
          "change_password.html",
          changeset: changeset,
          user: user
        )
      {:in_history} ->
        conn
        |> put_flash(:error, "You have already used that password. Please enter new password")
        |> render(
          "change_password.html",
          changeset: changeset,
          user: user
        )
    end
  end

   def change_password(conn, _params) do
    # insert template here
    user =
      conn.assigns.current_user.id
      |> UserContext.get_user!()

    changeset =
      user
      |> User.update_account_changeset()

    conn
    |> render(
      "change_password.html",
      user: user,
      changeset: changeset
    )
  end

  def update_password(conn, %{"user" => user_params}) do
    # insert function here
     user =
      conn.assigns.current_user.id
      |> UserContext.get_user!()

    changeset =
      user
      |> User.update_account_changeset(user_params)

    with true <- changeset.valid?,
         {:ok, _user} <- UserContext.update_password(changeset)
    do
      conn
      |> put_flash(:info, "Password successfully updated.")
      |> redirect(to: user_path(conn, :change_password))
    else
      false ->
        error_msg =
          cond do
            not is_nil(Keyword.get(changeset.errors, :old_password)) ->
              {message, validation} =
                Keyword.get(changeset.errors, :old_password)

                if Keyword.get(validation, :validation) == :required do
                  "Please enter current password"
                else
                  message
                end
            not is_nil(Keyword.get(changeset.errors, :password)) ->
              {message, validation} =
                Keyword.get(changeset.errors, :password)

                if Keyword.get(validation, :validation) == :required do
                  "Please enter new password"
                else
                  message
                end
            not is_nil(Keyword.get(changeset.errors, :password_confirmation)) ->
              {message, validation} =
                Keyword.get(changeset.errors, :password_confirmation)
                if Keyword.get(validation, :validation) == :required do
                  "Please enter confirm new password"
                else
                  message
                end
            true ->
              {"error", "error"}
          end

          if error_msg == "Invalid password" do
            conn
            |> render(
              "change_password.html",
              user: user,
              changeset: changeset,
              invalid_password: true
            )
          else
            conn
            |> put_flash(:error, error_msg)
            |> render(
              "change_password.html",
              user: user,
              changeset: changeset
            )
          end
    end
  end

  defp page_not_found(conn) do
    conn
    |> put_flash(:error, "Page not found!")
    |> redirect(to: user_path(conn, :index))
  end

  defp not_allowed(conn) do
    conn
    |> put_flash(:error, "Not allowed!")
    |> redirect(to: user_path(conn, :index))
  end

end
