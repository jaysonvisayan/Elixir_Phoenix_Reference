defmodule Innerpeace.Db.Schemas.LocationGroupTest do
  @moduledoc false
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.LocationGroup
  alias Ecto.UUID

  describe "test changeset" do
    test "with valid attributes" do
      params = %{
        name: "locationgroup name",
        description: "locationgroup des",
        created_by_id: UUID.bingenerate(),
        updated_by_id: UUID.bingenerate(),
        selecting_type: "Region"
      }

      changeset =
        %LocationGroup{}
        |> LocationGroup.changeset(params)

      assert changeset.valid?
    end

    test "with invalid attributes" do
      params = %{
        name: "location_group name",
        created_by_id: UUID.bingenerate(),
        updated_by_id: UUID.bingenerate()
      }

      changeset =
        %LocationGroup{}
        |> LocationGroup.changeset(params)

      refute changeset.valid?
    end
  end

end
