defmodule Innerpeace.Db.PractitionerScheduleSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.PractitionerContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case PractitionerContext.insert_or_update_pf_schedule(params) do
        {:ok, practitioner_schedule} ->
          practitioner_schedule
      end
    end)
  end
end
