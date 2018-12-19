defmodule Innerpeace.Db.Schemas.BenefitCoverageTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.BenefitCoverage

  test "changeset with valid attributes" do
    params = %{
      coverage_id: Ecto.UUID.generate(),
      benefit_id: Ecto.UUID.generate()
    }

    changeset = BenefitCoverage.changeset(%BenefitCoverage{}, params)
    assert changeset.valid?
  end
end
