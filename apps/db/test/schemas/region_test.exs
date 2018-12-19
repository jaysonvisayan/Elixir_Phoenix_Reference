defmodule Innerpeace.Db.Schemas.RegionTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Region

  test "changeset with valid attributes" do
    params = %{
      island_group: "island_group",
      region: "region"
    }

    changeset = Region.changeset(%Region{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      island_group: "island_group"
    }

    changeset = Region.changeset(%Region{}, params)
    refute changeset.valid?
  end
end
