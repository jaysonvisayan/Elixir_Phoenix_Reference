defmodule Innerpeace.Db.PractitionerSpecializationSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.PractitionerContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case PractitionerContext.insert_or_update_practitioner_specialization(params) do
        {:ok, practitioner_specialization} ->
          practitioner_specialization
      end
    end)
  end
end
