defmodule Innerpeace.Db.UserRoleSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.UserContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case UserContext.insert_or_update_user_role(params) do
        {:ok, user_role} ->
          user_role
        _ ->
          params
      end
    end)
  end
end
