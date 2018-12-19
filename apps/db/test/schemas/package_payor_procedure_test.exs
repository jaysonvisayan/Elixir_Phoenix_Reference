defmodule Innerpeace.Db.Schemas.PackagePayorProcedureTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.PackagePayorProcedure

  test "changeset with valid attributes" do
    params = %{
      payor_procedure_id: Ecto.UUID.generate(),
      package_id: Ecto.UUID.generate()
    }

    changeset = PackagePayorProcedure.changeset(%PackagePayorProcedure{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{}
    changeset = PackagePayorProcedure.changeset(%PackagePayorProcedure{}, params)

    refute changeset.valid?
  end

end
