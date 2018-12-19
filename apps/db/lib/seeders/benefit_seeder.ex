defmodule Innerpeace.Db.BenefitSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.BenefitContext

  def seed_health(data) do
    Enum.map(data, fn(params) ->
      case BenefitContext.insert_or_update_benefit_health(params) do
        {:ok, benefit} ->
          benefit
      end
    end)
  end

  def seed_riders(data) do
    Enum.map(data, fn(params) ->
      case BenefitContext.insert_or_update_benefit_riders(params) do
        {:ok, benefit} ->
          benefit
      end
    end)
  end
end
