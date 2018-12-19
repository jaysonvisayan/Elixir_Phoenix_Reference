defmodule Innerpeace.Db.BenefitCoverageSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.BenefitContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case BenefitContext.insert_or_update_benefit_coverage(params) do
        {:ok, benefit_coverage} ->
          benefit_coverage
      end
    end)
  end
end
