defmodule Innerpeace.Db.CoverageSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.CoverageContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case CoverageContext.insert_or_update_coverage(params) do
        {:ok, coverage} ->
          coverage
        _ ->
          params
      end
    end)
  end
end
