defmodule Innerpeace.Db.ProductCoverageSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.ProductContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case ProductContext.insert_or_update_product_coverage(params) do
        {:ok, product_coverage} ->
          product_coverage
        _ ->
          params
      end
    end)
  end
end
