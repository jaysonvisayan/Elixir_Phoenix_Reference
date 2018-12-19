defmodule Innerpeace.Db.AccountGroupAddressSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.AccountContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case AccountContext.insert_or_update_account_group_address(params) do
        {:ok, account_group_address} ->
          account_group_address
      end
    end)
  end
end
