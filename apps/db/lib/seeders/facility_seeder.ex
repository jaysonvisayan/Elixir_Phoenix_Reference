defmodule Innerpeace.Db.FacilitySeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.FacilityContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case FacilityContext.insert_or_update_facility(params) do
        {:ok, facility} ->
          facility
      end
    end)
  end
end
