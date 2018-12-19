defmodule Innerpeace.Db.RoomSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.RoomContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case RoomContext.insert_or_update_room(params) do
        {:ok, room} ->
          room
      end
    end)
  end
end
