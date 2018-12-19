defmodule Innerpeace.Db.Base.RoomContextTest do
  use Innerpeace.Db.SchemaCase
  use Innerpeace.Db.PayorRepo, :context

  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.Room,
    Db.Base.RoomContext
  }

  # @invalid_attrs %{}

  test "list_all_rooms*" do
    room =
      :room
      |> insert()
      |> Repo.preload([
        :room_logs, [
          facility_room_rates: [
            facility: :category]]])

    left =
      RoomContext.list_all_rooms
    right =
      room
      |> List.wrap
    assert left == right
  end

  test "get_room*" do
    room =
      :room
      |> insert()
      |> Repo.preload([
        :room_logs, [
          facility_room_rates: [
            facility: :category]]])

    left =
      room.id
      |> get_room
    right =
      room
      |> List.wrap

    assert left == right
  end

  test "create_room* with valid data creates a room" do
    params = %{
      code: "RoomCode1",
      type: "RoomType1",
      hierarchy: 1,
      ruv_rate: "1000"
    }
    assert {:ok, %Room{}} = create_room(params)
  end

  test "update_room* with valid data updates the room" do
    room =
      :room
      |> insert()
      |> Repo.preload([:room_logs])
    params = %{
      code: "RoomCode1",
      type: "RoomType1",
      hierarchy: 1,
      ruv_rate: "1000"

    }
    assert {:ok, %Room{}} = update_room(room, params)
  end

  test "clear_rooms* deletes all rooms of the given room" do
    room = insert(:room)
    RoomContext.clear_rooms(room.id)
    assert Enum.empty?(RoomContext.get_room(room.id))
  end

  test "delete room* deletes the room" do
    room = insert(:room)
    assert {:ok, %Room{}} = RoomContext.delete_room(room.id)
    assert_raise Ecto.NoResultsError, fn -> RoomContext.get_a_room(room.id) end
  end

  test "change_room* returns a room changeset" do
    room =
      :room
      |> insert(code: "RoomCode")
      |> Repo.preload([
        :room_logs, [
          facility_room_rates: [
            facility: :category]]])

    assert %Ecto.Changeset{} = change_room(room)
  end

  test "create room log with valid changeset" do
    room =
      :room
      |> insert(code: "RoomCode")
      |> Repo.preload([
        :room_logs, [
          facility_room_rates: [
            facility: :category]]])

    user = insert(:user, %{username: "admin", email: "admin@.admin.com"})
    params = %{
      code: "RoomCode1",
      type: "RoomType1",
      hierarchy: 1,
      ruv_rate: "1000"

    }
    changeset = Room.changeset(room, params)
    room_log = create_room_log(user, changeset)
    assert {:ok , %Room{}} = update_room(room, params)
    assert room_log.user_id == user.id
  end

end
