defmodule Innerpeace.Db.ProductBenefitSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.ProductContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case ProductContext.insert_or_update_product_benefit(params) do
        {:ok, product_benefit} ->
          product_benefit
      end
    end)
  end
end
