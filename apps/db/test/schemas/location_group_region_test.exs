defmodule Innerpeace.Db.Schemas.LocationGroupRegionTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.LocationGroupRegion

  test "changeset with valid attributes" do
    params = %{
      location_group_id: Ecto.UUID.generate(),
      region_id: Ecto.UUID.generate(),
      created_by_id: Ecto.UUID.generate(),
      updated_by_id: Ecto.UUID.generate()
    }

    changeset = LocationGroupRegion.changeset(%LocationGroupRegion{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      location_group_id: Ecto.UUID.generate(),
      created_by_id: Ecto.UUID.generate(),
      updated_by_id: Ecto.UUID.generate()
    }

    changeset = LocationGroupRegion.changeset(%LocationGroupRegion{}, params)
    refute changeset.valid?
  end
end
