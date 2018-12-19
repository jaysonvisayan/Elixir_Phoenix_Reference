defmodule Innerpeace.Db.BenefitDiagnosisSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.BenefitContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case BenefitContext.insert_or_update_benefit_diagnosis(params) do
        {:ok, benefit_diagnosis} ->
          benefit_diagnosis
      end
    end)
  end
end
