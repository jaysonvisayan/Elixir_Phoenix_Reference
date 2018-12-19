defmodule Innerpeace.Db.Schemas.FacilityFileTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.FacilityFile

  test "changeset with valid attributes" do
    params = %{
      facility_id: Ecto.UUID.generate(),
      file_id: Ecto.UUID.generate(),
      type: "test"
    }
    changeset = FacilityFile.changeset(%FacilityFile{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      type: "test"
    }
    changeset = FacilityFile.changeset(%FacilityFile{}, params)
    refute changeset.valid?
  end

end
