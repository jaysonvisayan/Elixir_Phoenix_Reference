defmodule RegistrationLinkWeb.Authorize do
  use Phoenix.Controller
  @permission Application.get_env(:registration_link, :permission)

  def can_access?(conn, params) do
    permissions = @permission.get_permission(conn)
    case any?(permissions, params.permissions) do
      true ->
        conn
      _ ->
        conn
        |> put_flash(:error, "You're not allowed to access this page")
        |> redirect(to: "/batch_processing")
        |> halt
    end
  end

  defp any?(required_permissions, user_permissions) do
    Enum.reduce_while(required_permissions, false, fn p, acc ->
      if Enum.member?(user_permissions, p), do: {:halt, true}, else: {:cont, acc}
    end)
  end

  def can_access_application?(conn, params) do
    applications = @permission.get_application(conn)
    case any_application?(applications, params.application) do
      true ->
        conn
      _ ->

        conn
        |> put_flash(:error, "You're not allowed to access this application")
        |> redirect(to: "/sign_in")
        |> halt
    end
  end

  defp any_application?(required_applications, user_application) do
    Enum.reduce_while(required_applications, false, fn a, acc ->
      if Enum.member?(user_application, a), do: {:halt, true}, else: {:cont, acc}
    end)
  end
end
