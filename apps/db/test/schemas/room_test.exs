defmodule Innerpeace.Db.Schemas.RoomTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Room

  test "changeset with valid attributes" do
    params = %{
      code: "RegRoom101",
      type: "Regular Room",
      hierarchy: 2,
      ruv_rate: "1000"
    }
    changeset = Room.changeset(%Room{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      code: "RegRoom101"
    }
    changeset = Room.changeset(%Room{}, params)

    refute changeset.valid?
  end
end
