defmodule Innerpeace.Db.PayorProcedureSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.ProcedureContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case ProcedureContext.insert_or_update_payor_procedure(params) do
        {:ok, payor_procedure} ->
          payor_procedure
      end
    end)
  end
end
