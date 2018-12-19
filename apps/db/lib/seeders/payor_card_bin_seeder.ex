defmodule Innerpeace.Db.PayorCardBinSeeder do
  @moduledoc """
  """

  alias Innerpeace.Db.Base.PayorCardBinContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case PayorCardBinContext.insert_or_update_payor_card_bin(params) do
        {:ok, payor_card_bin} ->
          payor_card_bin
        _ ->
          params
      end
    end)
  end
end
