defmodule Innerpeace.Db.Schemas.AuthorizationTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Authorization

  test "step3_changeset with valid data" do
    coverage = insert(:coverage)
    params = %{
      coverage_id: coverage.id
    }
    changeset = Authorization.step3_changeset(%Authorization{}, params)
    assert changeset.valid?
  end

  test "step3_changeset with invalid data" do
    params = %{
      coverage_id: ""
    }
    changeset = Authorization.step3_changeset(%Authorization{}, params)
    refute changeset.valid?
  end

  test "step4_consult_changeset with valid data" do
    member = insert(:member)
    facility = insert(:facility)
    coverage = insert(:coverage)

    params = %{
      consultation_type: "initial",
      chief_complaint: "test",
      member_id: member.id,
      facility_id: facility.id,
      coverage_id: coverage.id
    }

    changeset = Authorization.step4_consult_changeset(%Authorization{}, params)

    assert changeset.valid?
  end

  test "step4_consult_changeset with invalid data" do
    member = insert(:member)
    facility = insert(:facility)
    coverage = insert(:coverage)

    params = %{
      consultation_type: "",
      member_id: member.id,
      facility_id: facility.id,
      coverage_id: coverage.id
    }

    changeset = Authorization.step4_consult_changeset(%Authorization{}, params)

    refute changeset.valid?
  end
end
