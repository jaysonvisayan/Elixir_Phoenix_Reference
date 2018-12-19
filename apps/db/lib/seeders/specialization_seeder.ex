defmodule Innerpeace.Db.SpecializationSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.SpecializationContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case SpecializationContext.insert_or_update_specialization(params) do
        {:ok, specialization} ->
          specialization
      end
    end)
  end
end
