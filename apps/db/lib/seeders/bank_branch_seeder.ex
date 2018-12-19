defmodule Innerpeace.Db.BankBranchSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.BankBranchContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case BankBranchContext.insert_or_update_bank_branch(params) do
        {:ok, bank_branch} ->
          bank_branch
      end
    end)
  end
end
