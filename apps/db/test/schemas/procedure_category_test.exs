defmodule Innerpeace.Db.Schemas.ProcedureCategoryTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.ProcedureCategory

  test "changeset with valid attributes" do
    params = %{
      name: "application",
      code: "code"
    }
    changeset = ProcedureCategory.changeset(%ProcedureCategory{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{}
    changeset = ProcedureCategory.changeset(%ProcedureCategory{}, params)
    refute changeset.valid?
  end

end

