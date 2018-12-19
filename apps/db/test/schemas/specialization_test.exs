defmodule Innerpeace.Db.Schemas.SpecializationTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Specialization

  test "changeset with valid attributes" do
    params = %{
      name: "test123",
      type: "asd"
    }

    changeset = Specialization.changeset(%Specialization{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      name: nil
    }

    changeset = Specialization.changeset(%Specialization{}, params)
    refute changeset.valid?
  end
end
