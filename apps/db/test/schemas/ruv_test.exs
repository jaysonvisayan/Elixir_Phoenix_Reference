defmodule Innerpeace.Db.Schemas.RUVTest do
  use Innerpeace.Db.SchemaCase

  alias  Ecto.UUID
  alias Innerpeace.Db.Schemas.RUV

  test "changeset with valid attributes" do
    params = %{
      code: "test code",
      description: "test description",
      type: "Unit",
      value: 20,
      effectivity_date: Ecto.Date.cast!("2017-01-01"),
      created_by_id: UUID.bingenerate(),
      updated_by_id: UUID.bingenerate()
    }

    changeset = RUV.changeset(%RUV{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      code: "test code",
      type: "Unit",
      value: 20,
      effectivity_date: Ecto.Date.cast!("2017-01-01"),
      created_by_id: UUID.bingenerate(),
      updated_by_id: UUID.bingenerate()
    }

    changeset = RUV.changeset(%RUV{}, params)
    refute changeset.valid?
  end
end
