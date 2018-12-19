defmodule Innerpeace.PayorLink.Web.FacilityRoomRateControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  import Innerpeace.PayorLink.TestHelper

  @create_attrs %{
    facility_room_type: "some content",
    facility_room_rate: "some content"
  }

   setup do
    conn = build_conn()
     room = insert(:room)
     facility = insert(:facility)
    facility_room_rate = insert(:facility_room_rate,
                                room: room,
                                facility: facility,
                                facility_room_type: "some content",
                                facility_room_rate: "some content"
                    )
    user = insert(:user, is_admin: true)
    conn = sign_in(conn, user)
    {:ok, %{conn: conn, user: user, facility_room_rate: facility_room_rate, room: room, facility: facility}}
   end


  test "Add facility room rate when data is valid", %{conn: conn, facility: facility, room: room} do

    conn = post conn, facility_room_rate_path(conn, :create_room_rate, facility.id), facility_room_rate: Map.merge(@create_attrs, %{room_id: room.id, facility_id: facility.id})

  assert redirected_to(conn) == "/facilities/#{facility.id}?active=room"
  end

  # test "Update facility room rate when data is valid", %{conn: conn, facility: facility, room: room, facility_room_rate: facility_room_rate} do

  #   conn = post conn, facility_room_rate_path(conn, :update_room_rate, facility.id), facility_room_rate: Map.merge(@create_attrs, %{room_id: room.id, facility_id: facility.id, room_rate_id: facility_room_rate.id, facility_ruv_rate: "100", facility_room_number: "100"})

  # assert redirected_to(conn) == "/facilities/#{facility.id}?active=room"
  # end

  test "deletes chosen facility room rate", %{conn: conn, facility: facility, room: room} do
    facility_room_rate = insert(:facility_room_rate, facility_room_type: "some_content", facility_room_rate: "some content", facility_id: facility.id, room_id: room.id)
    conn = get conn, facility_room_rate_path(conn, :delete_room_rate, facility.id, facility_room_rate.id)
    assert redirected_to(conn) == "/facilities/#{facility.id}?active=room"

  end

end
