defmodule Innerpeace.Db.Base.Api.Vendor.PractitionerContextTest do
  @moduledoc false

  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Base.Api.Vendor.PractitionerContext, as: VendorPractitionerContext

  setup do
    facility =
      insert(
        :facility,
        code: "cmc",
        name: "CALAMBA MEDICAL CENTER",
        status: "Affiliated",
        affiliation_date: "2017-11-10",
        disaffiliation_date: "2018-11-23"
      )

    practitioner =
      insert(
        :practitioner,
        first_name: "Daniel",
        middle_name: "Murao",
        last_name: "Andal",
        code: "prac123",
        effectivity_from: "2017-11-13",
        effectivity_to: "2019-11-13"
      )

    practitioner_facility =
      insert(
        :practitioner_facility,
        affiliation_date: "2017-11-10",
        disaffiliation_date: "2018-11-17",
        payment_mode: "Umbrella",
        coordinator: true,
        consultation_fee: 400,
        cp_clearance_rate: 400,
        fixed: true,
        fixed_fee: 400,
        coordinator_fee: 400,
        facility_id: facility.id,
        practitioner_id: practitioner.id
      )

    specialization =
      insert(
        :specialization,
        name: "Anesthesiology"
      )

    insert(
      :practitioner_specialization,
      type: "Primary",
      specialization_id: specialization.id,
      practitioner_id: practitioner.id
    )

    {:ok, %{facility: facility, practitioner: practitioner, practitioner_facility: practitioner_facility}}
  end

  test "get_practitioner_by_code/1, returns practitioner by code" do
    practitioner = VendorPractitionerContext.get_practitioner_by_code("prac123")

    assert practitioner.first_name == "Daniel"
    assert practitioner.middle_name == "Murao"
    assert practitioner.last_name == "Andal"
  end

  test "get_facility_by_code/1, returns facility by code" do
    facility = VendorPractitionerContext.get_facility_by_code("cmc")

    assert facility.code == "cmc"
    assert facility.name == "CALAMBA MEDICAL CENTER"
    assert facility.status == "Affiliated"
  end

  test "get_practitioner_facility_by_code/1, returns practitioner facility by code" do
    practitioner = VendorPractitionerContext.get_practitioner_by_code("prac123")
    facility = VendorPractitionerContext.get_facility_by_code("cmc")
    pf = VendorPractitionerContext.get_practitioner_facility_by_code(practitioner.id, facility.id)

    assert pf.payment_mode == "Umbrella"
    assert pf.coordinator == true
    assert pf.fixed == true
  end

  test "get_practitioner/1, returns all practitioner with parameters" do
    practitioner =
      "daniel andal"
      |> VendorPractitionerContext.get_practitioner()
      |> List.first

    prac_sp =
      practitioner.practitioner_specializations
     |> Enum.map(&(&1.specialization.name))
     |> Enum.join(", ")

    assert practitioner.code == "prac123"
    assert prac_sp == "Anesthesiology"
  end
end
