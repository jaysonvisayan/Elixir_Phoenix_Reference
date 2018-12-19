defmodule Innerpeace.Db.Base.FacilityRoomRateContextTest do
  use Innerpeace.Db.SchemaCase
  use Innerpeace.Db.PayorRepo, :context
  alias Innerpeace.Db.Schemas.{
    FacilityRoomRate

  }
   alias Innerpeace.Db.Base.{
    FacilityRoomRateContext
  }

  # @invalid_attrs %{}

  test "list all facility_room_rates" do
    facility = insert(:facility)
    room = insert(:room)

    facility_room_rate = insert(:facility_room_rate,
    facility_id: facility.id,
    room_id: room.id,
    facility_room_type: "some content",
    facility_room_rate: "some content"
    )
    assert get_all_facility_room_rate(facility_room_rate.facility_id) ==
      [facility_room_rate] |> Repo.preload([:room, [facility: :category]])
  end

   test "get a facility_room_rate" do
    facility = insert(:facility)
     room = insert(:room)

    facility_room_rate = insert(:facility_room_rate,
    facility_id: facility.id,
    room_id: room.id,
    facility_room_type: "some content",
    facility_room_rate: "some content"
    )
     assert get_facility_room_rate(facility_room_rate.id) ==
       facility_room_rate |> Repo.preload([:room, [facility: :category]])
    end

   test "get room by code returns a room" do
     room = insert(:room, code: "some content")
      assert get_rooms(room.code) == [room]
   end

   test "check_rooms using code reuturn a rooms with facility_room_rate or rooms only" do
    facility = insert(:facility)
    room = insert(:room, code: "some content")

    insert(:facility_room_rate,
    facility_id: facility.id,
    room_id: room.id,
    facility_room_type: "some content",
    facility_room_rate: "some content"
    )
     assert check_rooms(room.code) == [room]
     |> Repo.preload([facility_room_rates: [facility: [:category, :type, facility_location_groups: :location_group]]])
   end

  test "create/set a facility room rate" do
    room = insert(:room)
    facility = insert(:facility)
    params = %{
      facility_id: facility.id,
      room_id: room.id,
      facility_room_type: "some content",
      facility_room_rate: "some content"
    }
    assert {:ok, %FacilityRoomRate{}} = FacilityRoomRateContext.set_facility_room_rate(params)
  end

  test "update a facility room rate" do
    room = insert(:room)
    facility = insert(:facility)

    facility_room_rate = insert(:facility_room_rate,
    facility_id: facility.id,
    room_id: room.id,
    facility_room_type: "some content",
    facility_room_rate: "some content"
    )

    params = %{
      facility_room_type: "some content",
      facility_room_rate: "some content"
    }
    assert {:ok, %FacilityRoomRate{}} = FacilityRoomRateContext.update_facility_room_rate(facility_room_rate, params)

  end

  test "remove all facility room rate" do
    room = insert(:room)
    facility = insert(:facility)

    insert(:facility_room_rate,
      facility_id: facility.id,
      room_id: room.id,
      facility_room_type: "some content",
      facility_room_rate: "some content")
    FacilityRoomRateContext.remove_all_facility_room_rate(facility.id)
  end

  test "remove facility room rate" do
    room = insert(:room)
    facility = insert(:facility)

    facility_room_rate = insert(:facility_room_rate,
    facility_id: facility.id,
    room_id: room.id,
    facility_room_type: "some content",
    facility_room_rate: "some content"
    )
    assert {:ok, %FacilityRoomRate{}} = delete_facility_room_rate_by_id(facility_room_rate.id)

  end

  test "changeset_facility_room_rate* returns a facility room rate changeset" do
    room = insert(:room)
    facility = insert(:facility)

    facility_room_rate = insert(:facility_room_rate,
    facility_id: facility.id,
    room_id: room.id,
    facility_room_type: "some content",
    facility_room_rate: "some content"
    )
    assert %Ecto.Changeset{} = FacilityRoomRateContext.changeset_facility_room_rate(facility_room_rate)
  end

end
