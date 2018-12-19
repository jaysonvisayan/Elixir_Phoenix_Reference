defmodule Innerpeace.Db.RegionSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.LocationGroupContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case LocationGroupContext.insert_or_update_region(params) do
        {:ok, region} ->
          region
      end
    end)
  end
end
