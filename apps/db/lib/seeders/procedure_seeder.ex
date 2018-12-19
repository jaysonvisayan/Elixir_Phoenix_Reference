defmodule Innerpeace.Db.ProcedureSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.ProcedureContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case ProcedureContext.insert_or_update_procedure(params) do
        {:ok, procedure} ->
          procedure
      end
    end)
  end
end
