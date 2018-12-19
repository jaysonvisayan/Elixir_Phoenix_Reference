defmodule Innerpeace.Db.AccountHierarchyOfEligibleDependentSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.AccountContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case AccountContext.insert_or_update_account_hoed(params) do
        {:ok, account_hoed} ->
          account_hoed
      end
    end)
  end
end
