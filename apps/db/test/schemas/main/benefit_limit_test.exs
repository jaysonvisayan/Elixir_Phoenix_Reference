defmodule Innerpeace.Db.Schemas.BenefitLimitTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.BenefitLimit
  alias Ecto.UUID

  describe "changeset benefit limit" do
    test "valid attributes" do
      params = %{
        benefit_id: UUID.generate(),
        limit_type: "Sessions",
        limit_percentage: "",
        limit_amount: "",
        limit_session: "1",
        limit_tooth: "",
        limit_quadtrant: "",
        coverages: "Dental",
        limit_classification: "Per Transaction"
      }

      changeset = BenefitLimit.changeset(%BenefitLimit{}, params)
      assert changeset.valid?
    end

    test "invalid attributes" do
      params = %{
        benefit_id: UUID.generate(),
        limit_type: "",
        limit_percentage: "",
        limit_amount: "",
        limit_session: "1",
        limit_tooth: "",
        limit_quadtrant: "",
        coverages: "Dental",
        limit_classification: "Per Transaction"
      }

      changeset = BenefitLimit.changeset(%BenefitLimit{}, params)
      refute changeset.valid?
    end
  end
end
