defmodule Innerpeace.Db.Schemas.PayorProcedureTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.PayorProcedure

  test "changeset with valid attributes" do
    params = %{
      description: "application",
      code: "code",
      procedure_id: Ecto.UUID.generate(),
      payor_id: Ecto.UUID.generate(),
      exclusion_type: "General Exclusion"
    }
    changeset = PayorProcedure.changeset(%PayorProcedure{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{}
    changeset = PayorProcedure.changeset(%PayorProcedure{}, params)
    refute changeset.valid?
  end

end

