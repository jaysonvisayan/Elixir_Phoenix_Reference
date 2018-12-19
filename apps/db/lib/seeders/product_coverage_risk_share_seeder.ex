defmodule Innerpeace.Db.ProductCoverageRiskShareSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.ProductContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case ProductContext.insert_or_update_product_coverage_risk_share(params) do
        {:ok, product_coverage_risk_share} ->
          product_coverage_risk_share
        _ ->
          params
      end
    end)
  end
end
