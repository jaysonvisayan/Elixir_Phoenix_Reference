defmodule Innerpeace.Db.DiagnosisCoverageSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.DiagnosisContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case DiagnosisContext.insert_or_update_diagnosis_coverage(params) do
        {:ok, diagnosis_coverage} ->
          diagnosis_coverage
      end
    end)
  end
end
