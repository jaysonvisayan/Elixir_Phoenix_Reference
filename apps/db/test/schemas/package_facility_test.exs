defmodule Innerpeace.Db.Schemas.PackageFacilityTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.PackageFacility

  test "changeset with valid attributes" do
    params = %{
      facility_id: Ecto.UUID.generate(),
      package_id: Ecto.UUID.generate()
    }

    changeset = PackageFacility.changeset(%PackageFacility{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{}
    changeset = PackageFacility.changeset(%PackageFacility{}, params)

    refute changeset.valid?
  end

end
