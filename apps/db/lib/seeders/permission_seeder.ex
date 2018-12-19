defmodule Innerpeace.Db.PermissionSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.PermissionContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case PermissionContext.insert_or_update_permission(params) do
        {:ok, user} ->
          user
      end
    end)
  end
end
