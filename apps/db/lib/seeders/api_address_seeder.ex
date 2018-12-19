defmodule Innerpeace.Db.ApiAddressSeeder do
  alias Innerpeace.Db.Base.ApiAddressContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case ApiAddressContext.insert_or_update_api_address(params) do
        {:ok, api_address} ->
          api_address
        _ ->
          params
      end
    end)
  end
end
