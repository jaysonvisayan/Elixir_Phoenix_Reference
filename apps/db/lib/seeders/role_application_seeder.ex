defmodule Innerpeace.Db.RoleApplicationSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.RoleContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case RoleContext.insert_or_update_role_application(params) do
        {:ok, role_application} ->
          role_application
        _ ->
          params
      end
    end)
  end
end
