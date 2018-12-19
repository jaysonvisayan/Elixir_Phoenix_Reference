defmodule Innerpeace.Db.RolePermissionSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.RoleContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case RoleContext.insert_or_update_role_permission(params) do
        {:ok, role_permission} ->
          role_permission
        _ ->
          params
      end
    end)
  end
end
