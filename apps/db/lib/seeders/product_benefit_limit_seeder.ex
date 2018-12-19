defmodule Innerpeace.Db.ProductBenefitLimitSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.ProductContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case ProductContext.insert_or_update_product_benefit_limit(params) do
        {:ok, product_benefit_limit} ->
          product_benefit_limit
      end
    end)
  end
end
