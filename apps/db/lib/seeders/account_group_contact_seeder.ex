defmodule Innerpeace.Db.AccountGroupContactSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.AccountContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case AccountContext.insert_or_update_account_group_contact(params) do
        {:ok, account_group_contact} ->
          account_group_contact
      end
    end)
  end
end
