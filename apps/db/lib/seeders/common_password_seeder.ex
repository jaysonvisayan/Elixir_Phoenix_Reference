defmodule Innerpeace.Db.CommonPasswordSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.UserContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case UserContext.insert_or_update_common_password(params) do
        {:ok, common_pass} ->
          common_pass
      end
    end)
  end
end
