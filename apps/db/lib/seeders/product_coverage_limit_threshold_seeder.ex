defmodule Innerpeace.Db.ProductCoverageLimitThresholdSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.ProductContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case ProductContext.insert_or_update_product_coverage_limit_threshold(params) do
        {:ok, product_coverage_limit_threshold} ->
          product_coverage_limit_threshold
        _ ->
          params
      end
    end)
  end
end
