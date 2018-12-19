defmodule Innerpeace.Db.Schemas.FacilityLocationGroupTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.FacilityLocationGroup
  alias Ecto.UUID

  test "changeset with valid attributes" do
    params = %{
      facility_id: UUID.bingenerate(),
      location_group_id: UUID.bingenerate()
    }

    changeset =
      %FacilityLocationGroup{}
      |> FacilityLocationGroup.changeset(params)

    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      location_group_id: UUID.bingenerate()
    }

    changeset =
      %FacilityLocationGroup{}
      |> FacilityLocationGroup.changeset(params)

    refute changeset.valid?
  end
end
