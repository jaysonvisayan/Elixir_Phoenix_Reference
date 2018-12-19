defmodule Innerpeace.Db.ProductCoverageRoomAndBoardSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.ProductContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case ProductContext.insert_or_update_product_coverage_room_and_board(params) do
        {:ok, product_coverage_room_and_board} ->
          product_coverage_room_and_board
        _ ->
          params
      end
    end)
  end
end
