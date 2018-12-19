defmodule Innerpeace.Db.Schemas.ExclusionProcedureTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.ExclusionProcedure

  test "changeset with valid attributes" do
    params = %{
      exclusion_id: Ecto.UUID.generate(),
      procedure_id: Ecto.UUID.generate()
    }
    changeset = ExclusionProcedure.changeset(%ExclusionProcedure{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{}
    changeset = ExclusionProcedure.changeset(%ExclusionProcedure{}, params)
    refute changeset.valid?
  end

end
