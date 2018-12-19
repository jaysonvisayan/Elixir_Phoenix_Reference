defmodule Innerpeace.Db.PractitionerFacilitySeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.PractitionerContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case PractitionerContext.insert_or_update_practitioner_facility(params) do
        {:ok, practitioner_facility} ->
          practitioner_facility
      end
    end)
  end
end
