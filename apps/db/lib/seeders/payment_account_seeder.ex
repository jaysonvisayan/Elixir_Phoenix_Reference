defmodule Innerpeace.Db.PaymentAccountSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.AccountContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case AccountContext.insert_or_update_payment_account(params) do
        {:ok, payment_account} ->
          payment_account
      end
    end)
  end
end
