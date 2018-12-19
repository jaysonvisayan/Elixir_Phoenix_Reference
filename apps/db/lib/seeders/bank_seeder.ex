defmodule Innerpeace.Db.BankSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.BankContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case BankContext.insert_or_update_bank(params) do
        {:ok, bank} ->
          bank
      end
    end)
  end
end
