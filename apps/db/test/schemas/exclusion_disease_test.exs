defmodule Innerpeace.Db.Schemas.ExclusionDiseaseTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.ExclusionDisease

  test "changeset with valid attributes" do
    params = %{
      exclusion_id: Ecto.UUID.generate(),
      disease_id: Ecto.UUID.generate()
    }
    changeset = ExclusionDisease.changeset(%ExclusionDisease{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{}
    changeset = ExclusionDisease.changeset(%ExclusionDisease{}, params)
    refute changeset.valid?
  end

end
