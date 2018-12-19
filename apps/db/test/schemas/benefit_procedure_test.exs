defmodule Innerpeace.Db.Schemas.BenefitProcedureTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.BenefitProcedure

  test "changeset with valid attributes" do
    params = %{
      procedure_id: Ecto.UUID.generate(),
      benefit_id: Ecto.UUID.generate()
    }

    changeset = BenefitProcedure.changeset(%BenefitProcedure{}, params)
    assert changeset.valid?
  end
end
