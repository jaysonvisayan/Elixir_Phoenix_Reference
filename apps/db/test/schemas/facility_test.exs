defmodule Innerpeace.Db.Schemas.FacilityTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Facility
  alias Ecto.UUID

  test "changeset with valid attributes" do
    params = %{
      code: "some content",
      name: "some content",
      license_name: "some content",
      phic_accreditation_from: Ecto.Date.utc,
      phic_accreditation_to: Ecto.Date.utc,
      phic_accreditation_no: "some content",
      status: "some content",
      affiliation_date: Ecto.Date.utc,
      disaffiliation_date: Ecto.Date.utc,
      phone_no: "some content",
      email_address: "some content",
      tin: "some content",
      prescription_term: 15,
      credit_term: 15,
      credit_limit: 15,
      no_of_beds: "some content",
      bond: 1.00,
      step: 1,
      created_by_id: UUID.bingenerate(),
      updated_by_id: UUID.bingenerate()
    }

    changeset = Facility.changeset(%Facility{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      code: "some content",
      name: "some content",
      license_name: "some content",
      phic_accreditation_from: "some content",
      phic_accreditation_to: "some content",
      phic_accreditation_no: "some content",
      status: "some content",
      affiliation_date: "some content",
      disaffiliation_date: "some content",
      phone_no: "some content",
      email_address: "some content",
      tin: 1,
      prescription_term: "15",
      credit_term: "15",
      credit_limit: "15",
      no_of_beds: 1,
      bond: "1.00",
      step: "1",
      created_by_id: "some string",
      updated_by_id: "some string"
    }

    changeset = Facility.changeset(%Facility{}, params)
    refute changeset.valid?
  end

  test "step1_changeset with valid required fields" do
    params = %{
      name: "some content",
      license_name: "some content",
      phic_accreditation_from: Ecto.Date.utc,
      phic_accreditation_to: Ecto.Date.utc,
      phic_accreditation_no: "some content",
      status: "some content",
      affiliation_date: Ecto.Date.utc,
      disaffiliation_date: Ecto.Date.utc,
      phone_no: "some content",
      email_address: "somecontent@ya.com",
      step: 1,
      created_by_id: UUID.bingenerate(),
      updated_by_id: UUID.bingenerate(),
      ftype_id: UUID.bingenerate(),
      fcategory_id: UUID.bingenerate(),
      code: "test"
    }

    changeset = Facility.step1_changeset(%Facility{}, params)
    assert changeset.valid?
  end

  test "step1_changeset with invalid required fields" do
    params = %{
      name: "some content",
      license_name: "some content",
      category: "some content",
      phic_accreditation_from: Ecto.Date.utc,
      phic_accreditation_to: Ecto.Date.utc,
      phic_accreditation_no: "some content",
      status: "some content",
      affiliation_date: Ecto.Date.utc,
      disaffiliation_date: Ecto.Date.utc,
      phone_no: "some content",
      email_address: "some content",
      step: 1,
      created_by_id: UUID.bingenerate(),
      updated_by_id: UUID.bingenerate()
    }

    changeset = Facility.step1_changeset(%Facility{}, params)
    refute changeset.valid?
  end

  test "step2_changeset with valid required fields" do
    params = %{
      line_1: "some content",
      line_2: "some content",
      city: "some content",
      province: "some content",
      region: "some content",
      country: "some content",
      postal_code: "some content",
      longitude: "some content",
      latitude: "some content",
      name: "some content",
      license_name: "some content",
      phic_accreditation_from: Ecto.Date.utc,
      phic_accreditation_to: Ecto.Date.utc,
      phic_accreditation_no: "some content",
      status: "some content",
      affiliation_date: Ecto.Date.utc,
      disaffiliation_date: Ecto.Date.utc,
      phone_no: "some content",
      email_address: "some content",
      step: 1,
      updated_by_id: UUID.bingenerate(),
      location_group_id: UUID.bingenerate()
    }

    changeset = Facility.step2_changeset(%Facility{}, params)
    assert changeset.valid?
  end

  test "step2_changeset with invalid required fields" do
    params = %{
      region: 1,
      country: "some content",
      postal_code: "some content",
      longitude: "some content",
      latitude: "some content",
      name: "some content",
      license_name: "some content",
      category: "some content",
      phic_accreditation_from: Ecto.Date.utc,
      phic_accreditation_to: Ecto.Date.utc,
      phic_accreditation_no: "some content",
      status: "some content",
      affiliation_date: Ecto.Date.utc,
      disaffiliation_date: Ecto.Date.utc,
      phone_no: "some content",
      email_address: "some content",
      step: 1,
      created_by_id: UUID.bingenerate(),
      updated_by_id: UUID.bingenerate()
    }

    changeset = Facility.step2_changeset(%Facility{}, params)
    refute changeset.valid?
  end

  test "step4_changeset with valid required fields" do
    params = %{
      tin: "some content",
      name: "some content",
      license_name: "some content",
      phic_accreditation_from: Ecto.Date.utc,
      phic_accreditation_to: Ecto.Date.utc,
      phic_accreditation_no: "some content",
      status: "some content",
      affiliation_date: Ecto.Date.utc,
      disaffiliation_date: Ecto.Date.utc,
      phone_no: "some content",
      email_address: "some content",
      step: 1,
      created_by_id: UUID.bingenerate(),
      updated_by_id: UUID.bingenerate(),
      ftype_id: UUID.bingenerate(),
      fcategory_id: UUID.bingenerate(),
      prescription_term: "123",
      credit_term: "123",
      credit_limit: "123",
      balance_biller: true,
      withholding_tax: "123",
      authority_to_credit: true,
      vat_status_id: UUID.bingenerate(),
      prescription_clause_id: UUID.bingenerate(),
      payment_mode_id: UUID.bingenerate(),
      releasing_mode_id: UUID.bingenerate()
    }
    changeset = Facility.step4_changeset(%Facility{}, params)
    assert changeset.valid?
  end

  test "step4_changeset with invalid required fields" do
    params = %{
      tin: 1,
      name: "some content",
      license_name: "some content",
      category: "some content",
      phic_accreditation_from: Ecto.Date.utc,
      phic_accreditation_to: Ecto.Date.utc,
      phic_accreditation_no: "some content",
      status: "some content",
      affiliation_date: Ecto.Date.utc,
      disaffiliation_date: Ecto.Date.utc,
      phone_no: "some content",
      email_address: "some content",
      step: 1,
      created_by_id: UUID.bingenerate(),
      updated_by_id: UUID.bingenerate()
    }

    changeset = Facility.step4_changeset(%Facility{}, params)
    refute changeset.valid?
  end
end
