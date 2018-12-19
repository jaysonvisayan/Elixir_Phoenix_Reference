defmodule Innerpeace.Db.UserSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.UserContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case UserContext.insert_or_update_user(params) do
        {:ok, user} ->
          user
      end
    end)
  end

  def seed_memberlink(data) do
    Enum.map(data, fn(params) ->
      case UserContext.insert_or_update_user_memberlink(params) do
        {:ok, user} ->
          user
      end
    end)
  end
end
