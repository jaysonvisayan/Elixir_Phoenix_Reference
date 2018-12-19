defmodule Innerpeace.Db.AccountGroupSeeder do
  @moduledoc """
  """

  alias Innerpeace.Db.Base.{AccountGroupContext}

  def seed(data) do
    Enum.map(data, fn(params) ->
      case AccountGroupContext.insert_or_update_account_group(params) do
        {:ok, account_group} ->
          account_group
      end
    end)
  end
end
