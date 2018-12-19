defmodule Innerpeace.Db.ContactSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.ContactContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case ContactContext.insert_or_update_contact(params) do
        {:ok, contact} ->
          contact
      end
    end)
  end
end
