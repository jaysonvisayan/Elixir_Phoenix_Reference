defmodule Innerpeace.Db.Schemas.ProcedureTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Procedure

  test "changeset with valid attributes" do
    params = %{
      code: "some content",
      description: "some content",
      type: "some content",
      procedure_category_id: Ecto.UUID.generate()
    }
    changeset = Procedure.changeset(%Procedure{}, params)
    assert changeset.valid?
  end
end
