defmodule Innerpeace.Db.ApplicationSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.ApplicationContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case ApplicationContext.insert_or_update_application(params) do
        {:ok, user} ->
          user
      end
    end)
  end
end
