defmodule Innerpeace.Db.Base.RoomContext do
  import Ecto.{Query, Changeset}, warn: false

  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.Room,
    Db.Schemas.RoomLog,
    Db.Schemas.FacilityRoomRate,
    Db.Schemas.Facility
  }

   def insert_or_update_room(params) do
    room = get_room_by_code(params.code)
    if is_nil(room) do
      create_room(params)
    else
      params =
        params
        |> Map.delete(:code)
      update_room(room, params)
    end
   end

  def get_room_by_code(code) do
    Room
    |> Repo.get_by(code: code)
  end

  def get_room_by_id(id) do
    Room
    |> Repo.get(id)
  end

  def list_all_rooms do
    Room
    |> Repo.all
    |> Repo.preload([:room_logs])
    |> Repo.preload([facility_room_rates: [facility: [:category, :type]]])
  end

  def get_room(room_id) do
    Room
    |> where([r], r.id == ^room_id)
    |> Repo.all
    |> Repo.preload([:room_logs])
    |> Repo.preload([facility_room_rates: [facility: [:category, :type]]])
  end

  def get_a_room(id) do
    Room
    |> Repo.get!(id)
    |> Repo.preload([:room_logs])
    |> Repo.preload([facility_room_rates: [facility: [:category, :type, [facility_location_groups: :location_group]]]])
  end

  def create_room(attrs \\ %{}) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  def update_room(rooms, room_params) do
    rooms
    |> Room.changeset(room_params)
    |> Repo.update()
  end

  def clear_rooms(room_id) do
    Room
    |> where([r], r.id == ^room_id)
    |> Repo.delete_all()
  end

  def delete_room(id) do
    room = get_a_room(id)
    room
    |> Repo.delete()
  end

  def change_room(%Room{} = room) do
    Room.changeset(room, %{})
  end

  def get_all_room_type do
    Room
    |> select([:type])
    |> Repo.all
    |> Repo.preload([:room_logs])
    |> Repo.preload([facility_room_rates: [facility: [:category, :type]]])
  end

  def get_all_room_code_and_type do
    Room
    |> select([:code, :type])
    |> Repo.all
    |> Repo.preload([:room_logs])
    |> Repo.preload([facility_room_rates: [facility: [:category, :type]]])
  end

   # Room Logs in Room Page

  def create_room_log(user, changeset) do
    if Enum.empty?(changeset.changes) == false do
      changes = changes_to_string(changeset)
      message = "#{user.username} edited #{changes}."

      insert_log(%{
        room_id: changeset.data.id,
        user_id: user.id,
        message: message
      })
    end
  end

  defp changes_to_string(changeset) do
    changes = for {key, new_value} <- changeset.changes, into: [] do
      "#{transform_atom(key)} from #{Map.get(changeset.data, key)} to #{new_value}"
    end
    changes |> Enum.join(", ")
  end

  defp transform_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&(String.capitalize(&1)))
    |> Enum.join(" ")
  end

  defp insert_log(params) do
    changeset = RoomLog.changeset(%RoomLog{}, params)
    Repo.insert!(changeset)
  end

  def get_room_logs(room_id) do
    RoomLog
    |> where([rl], rl.room_id == ^room_id)
    |> Repo.all()
  end

  # End of Room Logs in Room Page

end
