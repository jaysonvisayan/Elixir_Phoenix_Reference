defmodule Innerpeace.Db.RoleSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.RoleContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case RoleContext.insert_or_update_role(params) do
        {:ok, user} ->
          user
      end
    end)
  end
end
