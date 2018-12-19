defmodule Innerpeace.Db.UserAccountSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.UserContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case UserContext.insert_or_update_user_account(params) do
        {:ok, user_account} ->
          user_account
        _ ->
          params
      end
    end)
  end
end
