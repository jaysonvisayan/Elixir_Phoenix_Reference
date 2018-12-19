defmodule Innerpeace.Db.AccountProductBenefitSeeder do
  @moduledoc """
  """

  alias Innerpeace.Db.Base.{AccountContext}

  def seed(data) do
    Enum.map(data, fn(params) ->
      case AccountContext.insert_or_update_account_product_benefit(params) do
        {:ok, account_product_benefit} ->
          account_product_benefit
      end
    end)
  end
end
