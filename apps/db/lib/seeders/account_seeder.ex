defmodule Innerpeace.Db.AccountSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.AccountContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case AccountContext.insert_or_update_account(params) do
        {:ok, account} ->
          account
      end
    end)
  end
end
