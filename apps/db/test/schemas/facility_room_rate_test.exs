defmodule Innerpeace.Db.Schemas.FacilityRoomRateTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.FacilityRoomRate

  test "changeset with valid attributes" do
    params = %{
      facility_id: "388412e1-1668-42b7-86d2-bd57f46678b6",
      room_id: "388412e1-1668-42b7-86d2-bd57f46678b6i",
      facility_room_type: "some content",
      facility_room_rate: "some content"
    }
    changeset = FacilityRoomRate.changeset(%FacilityRoomRate{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      facility_id: "",
      room_id: ""
    }
    changeset = FacilityRoomRate.changeset(%FacilityRoomRate{}, params)
    refute changeset.valid?
  end

end

