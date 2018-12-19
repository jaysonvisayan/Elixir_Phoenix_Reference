defmodule Innerpeace.Db.BenefitProcedureSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.BenefitContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case BenefitContext.insert_or_update_benefit_procedure(params) do
        {:ok, benefit_procedure} ->
          benefit_procedure
      end
    end)
  end
end
