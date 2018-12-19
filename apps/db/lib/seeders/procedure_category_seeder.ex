defmodule Innerpeace.Db.ProcedureCategorySeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.ProcedureCategoryContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case ProcedureCategoryContext.insert_or_update_procedure_category(params) do
        {:ok, procedure_category} ->
          procedure_category
      end
    end)
  end
end
