defmodule Innerpeace.Db.DropdownSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.DropdownContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case DropdownContext.insert_or_update_dropdown(params) do
        {:ok, dropdown} ->
          dropdown
      end
    end)
  end
end
