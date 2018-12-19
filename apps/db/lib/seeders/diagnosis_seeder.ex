defmodule Innerpeace.Db.DiagnosisSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.DiagnosisContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case DiagnosisContext.insert_or_update_diagnosis(params) do
        {:ok, diagnosis} ->
          diagnosis
      end
    end)
  end
end
