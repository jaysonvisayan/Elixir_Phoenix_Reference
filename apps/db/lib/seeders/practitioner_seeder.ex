defmodule Innerpeace.Db.PractitionerSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.PractitionerContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case PractitionerContext.insert_or_update_practitioner(params) do
        {:ok, practitioner} ->
          practitioner
      end
    end)
  end
end
