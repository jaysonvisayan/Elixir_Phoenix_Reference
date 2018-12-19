defmodule Innerpeace.Authorize do
  @moduledoc """
  """

  use Phoenix.Controller
  @permission Application.get_env(:payor_link, :permission)

  def can_access?(conn, params) do
    permissions = @permission.get_permission(conn)
    case any?(permissions, params.permissions) do
      true ->
        conn
      _ ->
        conn
        |> put_flash(:error, "You're not allowed to access this page")
        |> redirect(to: "/")
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

  def valid_uuid?(conn, params) do
    keys = Enum.into(conn.params, [], fn({k, v}) -> k end)
    ids = Enum.into(conn.params, [], fn({k, v}) ->
      if String.contains?(k, "id"), do: v end)
    ids =
      ids
      |> Enum.uniq()
      |> List.delete(nil)
    key = Enum.join(keys, " ")
    with true <- String.contains?(key, "id"),
         {:ok} <- check_many_valid_ids(ids)
    do
      conn
    else
      {:invalid_id} ->
        conn
        |> put_flash(:error, "Invalid ID")
        |> redirect(to: "/#{params.origin}")
        |> halt
      _ ->
        conn
    end
  end

  defp check_many_valid_ids(ids) do
    returns = for id <- ids do
      with {true, id} <- Innerpeace.Db.Base.Api.UtilityContext.valid_uuid?(id)
      do
        true
      else
        _ ->
          false
      end
    end
    if Enum.member?(returns, false) do
      {:invalid_id}
    else
      {:ok_id}
    end
  end

end
