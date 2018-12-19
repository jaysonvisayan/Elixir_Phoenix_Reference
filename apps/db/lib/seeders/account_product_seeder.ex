defmodule Innerpeace.Db.AccountProductSeeder do
  @moduledoc """
  """

  alias Innerpeace.Db.Base.{AccountContext}

  def seed(data) do
    Enum.map(data, fn(params) ->
      case AccountContext.insert_or_update_account_product(params) do
        {:ok, account_product} ->
          account_product
      end
    end)
  end
end
