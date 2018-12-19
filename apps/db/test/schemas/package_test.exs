defmodule Innerpeace.Db.Schemas.PackageTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Package

  test "changeset with valid attributes" do
    params = %{
      code: "CODE1",
      name: "PACKAGE",
      step: 2
    }

    changeset = Package.changeset(%Package{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      name: "PACKAGE1"
    }
    changeset = Package.changeset(%Package{}, params)

    refute changeset.valid?
  end
end
