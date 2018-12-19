defmodule Innerpeace.Db.Schemas.FacilityPayorProcedureTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.FacilityPayorProcedure

  test "changeset with valid attributes" do
    params = %{
      code: "some content",
      name: "some content",
      amount: 1123,
      start_date: Ecto.Date.utc,
      payor_procedure_id: Ecto.UUID.bingenerate(),
      facility_id: Ecto.UUID.bingenerate(),
    }

    changeset = FacilityPayorProcedure.changeset(%FacilityPayorProcedure{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      code: "some content",
      name: "some content"
    }

    changeset = FacilityPayorProcedure.changeset(%FacilityPayorProcedure{}, params)
    refute changeset.valid?
  end
end

