defmodule Innerpeace.Db.PhoneSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.PhoneContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case PhoneContext.insert_or_update_phone(params) do
        {:ok, phone} ->
          phone
      end
    end)
  end
end
