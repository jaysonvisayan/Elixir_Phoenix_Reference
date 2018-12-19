defmodule Innerpeace.Db.BenefitLimitSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.BenefitContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case BenefitContext.insert_or_update_benefit_limit(params) do
        {:ok, benefit_limit} ->
          benefit_limit
      end
    end)
  end
end
