defmodule Innerpeace.Db.ProductSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.ProductContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case ProductContext.insert_or_update_product(params) do
        {:ok, product} ->
          product
        _ ->
          params
      end
    end)
  end
end
