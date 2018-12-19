defmodule Innerpeace.Db.PayorSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.PayorContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case PayorContext.insert_or_update_payor(params) do
        {:ok, payor} ->
          payor
        _ ->
          params
      end
    end)
  end
end
