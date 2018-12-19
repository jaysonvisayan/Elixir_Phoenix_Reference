defmodule Innerpeace.Db.Base.Api.PractitionerContextTest do
  use Innerpeace.Db.SchemaCase
  # alias Innerpeace.Db.{
  #   Repo,
  #   Schemas.Practitioner,
  #   Schemas.PractitionerSpecialization,
  #   Schemas.PractitionerContact,
  #   Schemas.Contact,
  #   Schemas.Phone,
  #   Schemas.Fax,
  #   Schemas.Bank,
  #   Schemas.PractitionerFacility,
  #   Schemas.PractitionerFacilityPractitionerType,
  #   Schemas.PractitionerFacilityContact,
  #   Schemas.PractitionerAccount,
  #   Schemas.PractitionerAccountContact,
  #   Schemas.PractitionerSchedule,
  #   Schemas.AccountGroupAddress,
  #   Schemas.PractitionerFacilityRoom,
  #   Schemas.FacilityRoomRate,
  #   Schemas.PractitionerLog,
  #   Schemas.Specialization,
  #   Schemas.Facility,
  #   Schemas.AccountGroup,
  #   Schemas.Account
  # }

  alias Innerpeace.Db.Base.Api.PractitionerContext

  test "validate_details/1 returns practitioner using valid attributes" do
    practitioner = insert(:practitioner, birth_date: Ecto.Date.cast!("1997-01-30"), first_name: "Daniel Eduard", last_name: "Andal", middle_name: "Murao", prc_no: "1231231", suffix: "Dr", affiliated: "Yes")
    insert(:bank, practitioner: practitioner)
    contact = insert(:contact)
    insert(:phone, contact: contact)
    insert(:email, contact: contact)
    account_group = insert(:account_group)
    facility = insert(:facility)
    specialization = insert(:specialization)
    insert(:practitioner_contact, contact: contact, practitioner: practitioner)
    insert(:practitioner_specialization, specialization: specialization, practitioner: practitioner)
    insert(:practitioner_facility, facility: facility, practitioner: practitioner)
    insert(:practitioner_account, account_group: account_group, practitioner: practitioner)
    params = %{
      "first_name" => "Daniel Eduard",
      "middle_name" => "Murao",
      "last_name" => "Andal",
      "prc_no" => "1231231",
      "extension" => "Dr"
    }

    assert {:ok, _practitioner, _practitioner_contact, _practitioner_account, _practitioner_facility, _practitioner_specialization, _practitioner_bank} = PractitionerContext.validate_details(params)

  end

  test "validate_details/1 does not returns practitioner using invalid attributes" do
    practitioner = insert(:practitioner, birth_date: Ecto.Date.cast!("1997-01-30"), first_name: "Daniel Eduard", last_name: "Andal", middle_name: "Murao", prc_no: "1231231", suffix: "Dr", affiliated: "Yes")
    insert(:bank, practitioner: practitioner)
    contact = insert(:contact)
    insert(:phone, contact: contact)
    insert(:email, contact: contact)
    account_group = insert(:account_group)
    facility = insert(:facility)
    specialization = insert(:specialization)
    insert(:practitioner_contact, contact: contact, practitioner: practitioner)
    insert(:practitioner_specialization, specialization: specialization, practitioner: practitioner)
    insert(:practitioner_facility, facility: facility, practitioner: practitioner)
    insert(:practitioner_account, account_group: account_group, practitioner: practitioner)
    params = %{
      "first_name" => "",
      "middle_name" => "",
      "last_name" => "",
      "prc_no" => "",
      "extension" => ""
    }
    assert {:error, "First Name is required"} == PractitionerContext.validate_details(params)
  end

  test "validate_details/1 does not returns practitioner when practitioner is not found" do
    practitioner = insert(:practitioner, birth_date: Ecto.Date.cast!("1997-01-30"), first_name: "Daniel Eduard", last_name: "Andal", middle_name: "Murao", prc_no: "1231231", suffix: "Dr", affiliated: "Yes")
    insert(:bank, practitioner: practitioner)
    contact = insert(:contact)
    insert(:phone, contact: contact)
    insert(:email, contact: contact)
    account_group = insert(:account_group)
    facility = insert(:facility)
    specialization = insert(:specialization)
    insert(:practitioner_contact, contact: contact, practitioner: practitioner)
    insert(:practitioner_specialization, specialization: specialization, practitioner: practitioner)
    insert(:practitioner_facility, facility: facility, practitioner: practitioner)
    insert(:practitioner_account, account_group: account_group, practitioner: practitioner)
    params = %{
      "first_name" => "idkawdj",
      "middle_name" => "dwadaw",
      "last_name" => "dawdaw",
      "prc_no" => "dwadaw",
      "extension" => "dwada"
    }
    assert {:error, "The details you have entered is invalid"} == PractitionerContext.validate_details(params)
  end

  test "validate_details/1 returns practitioner using valid attributes but not affiliated" do
    practitioner = insert(:practitioner, birth_date: Ecto.Date.cast!("1997-01-30"), first_name: "Daniel Eduard", last_name: "Andal", middle_name: "Murao", prc_no: "1231231", suffix: "Dr", affiliated: "No")
    insert(:bank, practitioner: practitioner)
    contact = insert(:contact)
    insert(:phone, contact: contact)
    insert(:email, contact: contact)
    account_group = insert(:account_group)
    facility = insert(:facility)
    specialization = insert(:specialization)
    insert(:practitioner_contact, contact: contact, practitioner: practitioner)
    insert(:practitioner_specialization, specialization: specialization, practitioner: practitioner)
    insert(:practitioner_facility, facility: facility, practitioner: practitioner)
    insert(:practitioner_account, account_group: account_group, practitioner: practitioner)
    params = %{
      "first_name" => "Daniel Eduard",
      "middle_name" => "Murao",
      "last_name" => "Andal",
      "prc_no" => "1231231",
      "extension" => "Dr"
    }

    assert {:error, "The Practitioner you have entered is not affiliated"} == PractitionerContext.validate_details(params)

  end

  ### for POST API Practitioner/new
  # jose valim's comment
  #     we don't know how to encode a list with maps with less or more than one element inside. So we should
  #     raise whenever there is a map in a list and the number of elements in the map is different than 1.

  #  test " validate_new_practitioner/2 returns practitioner using valid attributes using MediLink Xp Card" do
  #    user = insert(:user)
  #    specialization1 = insert(:specialization, name: "Radiology")
  #    specialization2 = insert(:specialization, name: "Dermatology")
  #    specialization3 = insert(:specialization, name: "Psychiatry")
  #
  #    params = %{
  #      "code" => "PRA-111111",
  #      "first_name" => "joseph",
  #      "middle_name" => "agustin",
  #      "last_name" => "canilao",
  #      "birth_date" => "1993-10-25",
  #      "suffix" => "a.",
  #      "gender" => "Male",
  #      "affiliated" => "Yes",
  #      "prc_no" => "312313213133",
  #      "status" => "Affiliated",
  #      "effectivity_from" => "2017-10-23",
  #      "effectivity_to" => "2017-10-23",
  #      "specialization_name" => "Psychiatry",
  #      "sub_specialization_name" => ["Radiology", "Dermatology"],
  #      "contact" => %{
  #        "email" => ["joseph_canilao@medilink.com.ph", "agustin.canilao@gmail.com"],
  #        "fax" => ["1339931"],
  #        "mobile_no" => ["09195608936", "09195608933"],
  #        "tel_no" => ["444-23-54"]
  #      },
  #      "exclusive" => ["PCS", "NON-PCS"],
  #      "prescription_period" => "31",
  #      "tin" => "442222333333",
  #      "withholding_tax" => "50",
  #      "vat_status" => "VAT-able",
  #      "payment_type" => "MediLink XP Card",
  #      "xp_card_no" => "412414212421412"
  #    }
  #
  #    assert {:ok, practitioner} = PractitionerContext.validate_new_practitioner(user, params)
  #  end
  #
  #  test " validate_new_practitioner/2 returns practitioner using valid attributes using Bank" do
  #    user = insert(:user)
  #    specialization1 = insert(:specialization, name: "Radiology")
  #    specialization2 = insert(:specialization, name: "Dermatology")
  #    specialization3 = insert(:specialization, name: "Psychiatry")
  #    bank = insert(:bank, account_name: "Metropolitan Bank and Trust Company")
  #
  #    params = %{
  #      "code" => "PRA-111111",
  #      "first_name" => "joseph",
  #      "middle_name" => "agustin",
  #      "last_name" => "canilao",
  #      "birth_date" => "1993-10-25",
  #      "suffix" => "a.",
  #      "gender" => "Male",
  #      "affiliated" => "Yes",
  #      "prc_no" => "312313213133",
  #      "status" => "Affiliated",
  #      "effectivity_from" => "2017-10-23",
  #      "effectivity_to" => "2017-10-23",
  #      "specialization_name" => "Psychiatry",
  #      "sub_specialization_name" => ["Radiology", "Dermatology"],
  #      "contact" => %{
  #        "email" => ["joseph_canilao@medilink.com.ph", "agustin.canilao@gmail.com"],
  #        "fax" => ["1339931"],
  #        "mobile_no" => ["09195608936", "09195608933"],
  #        "tel_no" => ["444-23-54"]
  #      },
  #      "exclusive" => ["PCS", "NON-PCS"],
  #      "prescription_period" => "31",
  #      "tin" => "442222333333",
  #      "withholding_tax" => "50",
  #      "vat_status" => "VAT-able",
  #      "payment_type" => "Bank",
  #      "bank_name" => "Metropolitan Bank and Trust Company",
  #      "account_no" => "412414212421412"
  #    }
  #
  #    assert {:ok, practitioner} = PractitionerContext.validate_new_practitioner(user, params)
  #  end
  #
  #  test " validate_new_practitioner/2 returns practitioner using valid attributes using Check" do
  #    user = insert(:user)
  #    specialization1 = insert(:specialization, name: "Radiology")
  #    specialization2 = insert(:specialization, name: "Dermatology")
  #    specialization3 = insert(:specialization, name: "Psychiatry")
  #
  #    params = %{
  #      "code" => "PRA-111111",
  #      "first_name" => "joseph",
  #      "middle_name" => "agustin",
  #      "last_name" => "canilao",
  #      "birth_date" => "1993-10-25",
  #      "suffix" => "a.",
  #      "gender" => "Male",
  #      "affiliated" => "Yes",
  #      "prc_no" => "312313213133",
  #      "status" => "Affiliated",
  #      "effectivity_from" => "2017-10-23",
  #      "effectivity_to" => "2017-10-23",
  #      "specialization_name" => "Psychiatry",
  #      "sub_specialization_name" => ["Radiology", "Dermatology"],
  #      "contact" => %{
  #        "email" => ["joseph_canilao@medilink.com.ph", "agustin.canilao@gmail.com"],
  #        "fax" => ["1339931"],
  #        "mobile_no" => ["09195608936", "09195608933"],
  #        "tel_no" => ["444-23-54"]
  #      },
  #      "exclusive" => ["PCS", "NON-PCS"],
  #      "prescription_period" => "31",
  #      "tin" => "442222333333",
  #      "withholding_tax" => "50",
  #      "vat_status" => "VAT-able",
  #      "payment_type" => "Check",
  #      "payee_name" => "Amerigo Vespucci"
  #    }
  #
  #    assert {:ok, practitioner} = PractitionerContext.validate_new_practitioner(user, params)
  #  end

  test "get_practitioner_code_vendor_code/1, get practitioner code by vendor code with valid parameter" do
    practitioner = insert(:practitioner, vendor_code: "123")

    result = PractitionerContext.get_practitioner_code_by_vendor_code("123")
    assert practitioner.code == result
  end

  test "get_facility_code_vendor_code/1, get facility code by vendor code with invalid parameter" do
    practitioner = insert(:practitioner, vendor_code: "123")

    result = PractitionerContext.get_practitioner_code_by_vendor_code("1123")
    refute practitioner.code == result
  end

  test "get_practitioner_specializations/1 success" do
    practitioner = insert(:practitioner)
    specialization = insert(:specialization)
    insert(:practitioner_specialization, practitioner: practitioner, specialization: specialization)

    result = PractitionerContext.get_practitioner_specializations(practitioner.id)
    refute Enum.empty?(result)
  end

  test "get_practitioner_specializations/1 failed" do
    practitioner = insert(:practitioner)

    result = PractitionerContext.get_practitioner_specializations(practitioner.id)
    assert Enum.empty?(result)
  end

end
