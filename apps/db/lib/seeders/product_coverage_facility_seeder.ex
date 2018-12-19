defmodule Innerpeace.Db.ProductCoverageFacilitySeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.ProductContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case ProductContext.insert_or_update_product_coverage_facility(params) do
        {:ok, product_coverage_facility} ->
          product_coverage_facility
        _ ->
          params
      end
    end)
  end
end
