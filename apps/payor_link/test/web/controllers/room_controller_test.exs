defmodule Innerpeace.PayorLink.Web.RoomControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper

  setup do
    conn = build_conn()
    room = insert(:room, %{code: "Room Code", type: "Room Type 1", hierarchy: 1})
    user = fixture(:user_permission, %{keyword: "manage_rooms", module: "Rooms"})
    conn = authenticated(conn, user)
    {:ok, %{conn: conn, room: room}}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, room_path(conn, :index)
    assert html_response(conn, 200) =~ "Rooms"
  end

  test "renders form for new room", %{conn: conn} do
    conn = get conn, room_path(conn, :new)
    assert html_response(conn, 200) =~ "Add Room"
  end

  test "creates rooms and redirects to index when data is valid", %{conn: conn} do
    params = %{
      "code" => "Room Code 1",
      "type" => "Room Type 2",
      "hierarchy" => "1",
      "ruv_rate" => "1000"
       }
    conn = post conn, room_path(conn, :create), room: params
    assert redirected_to(conn) == room_path(conn, :index)
  end

  test "creates rooms and redirects to index when parameters are invalid", %{conn: conn} do
    params = %{
       }
    conn = post conn, room_path(conn, :create), room: params
    assert html_response(conn, 200)  =~ "Rooms"
  end

  test "does not create rooms with invalid attributes", %{conn: conn} do
    params = %{
      "code" => "Room Code",
      "hierarchy" => "1"
       }
    conn = post conn, room_path(conn, :create), room: params
    assert html_response(conn, 200) =~ "Add Room"
  end

  test "updates room and redirects to index when data is valid", %{conn: conn, room: room} do
    params = %{
      "code" => "Room Code",
      "type" => "Room Type 3",
      "hierarchy" => "2",
      "ruv_rate" => "1000"
       }
    conn = post conn, room_path(conn, :update, room, room: params)
    assert redirected_to(conn) == room_path(conn, :index)
  end

  test "does not update room with invalid attributes", %{conn: conn, room: room} do
    params = %{
      "code" => "Room Code",
      "type" => "Room Type 1",
      "hierarchy" => "hierarchy"
       }
    conn = post conn, room_path(conn, :update, room, room: params)

    assert redirected_to(conn) == room_path(conn, :edit, room)
    assert conn.private[:phoenix_flash]["error"] == "Error updating room!"
  end

  test "does not update room with invalid attributes(null bytes)", %{conn: conn, room: room} do
    params = %{
      "code" => "Room Code",
      "type" => "Room Type 1",
      "hierarchy" => "\x00"
       }
    conn = post conn, room_path(conn, :update, room, room: params)

    assert redirected_to(conn) == room_path(conn, :edit, room)
    assert conn.private[:phoenix_flash]["error"] == "Error updating room!"
  end

  test "does not create room and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, room_path(conn, :create), room: %{type: nil}
    assert html_response(conn, 200) =~ "Add Room"
  end

end
