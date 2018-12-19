defmodule Innerpeace.Db.Base.FacilityContextTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Base.{
    FacilityContext
  }

  alias Ecto.UUID

  test "create_facility with valid attributes" do
    # Setup
    type = insert(:dropdown, type: "Facility Type")
    category = insert(:dropdown, type: "Facility Category")
    user = insert(:user, is_admin: true)
    params = %{
      "ftype_id" => type.id,
      "fcategory_id" => category.id,
      "created_by_id" => user.id,
      "updated_by_id" => user.id,
      "step" => 1,
      "name" => "Test provider 1",
      "license_name" => "test",
      "phic_accreditation_from" => "2017-02-02",
      "phic_accreditation_to" => "2017-02-02",
      "phic_accreditation_no" => "1",
      "status" => "Pending",
      "affiliation_date" => "2017-02-02",
      "code" => "test code"
    }

    # Logic
    {status, facility} = FacilityContext.create_facility(user.id, params)

    # Assertion
    assert status == :ok
    assert facility.name == "Test provider 1"
  end

  test "create_facility with invalid attributes" do
    # Setup
    params = %{}
    user = insert(:user)

    # Logic
    {status, result} = FacilityContext.create_facility(user.id, params)

    # Assertion
    assert status == :error
    refute result.valid?
  end

  test "create_facility_contact with valid attributes" do
    # Setup
    facility = insert(:facility,
                      name: "Test provider 1"
    )
    contact = insert(:contact,
                     first_name: "Janna Mamer",
                     last_name: "Dela Cruz",
                     department: "SDDD",
                     designation: "TL"
    )
    params = %{
      facility_id: facility.id,
      contact_id: contact.id
    }

    # Logic
    {status, result} = FacilityContext.create_facility_contact(params)

    # Assertion
    assert status == :ok
    assert result.facility_id == facility.id
    assert result.contact_id == contact.id
  end

  test "create_facility_contact with invalid attributes" do
    # Setup
    params = %{}

    # Logic
    {status, result} = FacilityContext.create_facility_contact(params)

    # Assertion
    assert status == :error
    refute result.valid?
  end

  test "update_step1_facility with valid attributes" do
    # Setup
    type = insert(:dropdown, type: "Facility Type")
    category = insert(:dropdown, type: "Facility Category")
    user = insert(:user, is_admin: true)
    facility = insert(:facility)
    params = %{
      "ftype_id" => type.id,
      "fcategory_id" => category.id,
      "updated_by_id" => user.id,
      "created_by_id" => user.id,
      "step" => 1,
      "name" => "Test provider 1",
      "license_name" => "test",
      "phic_accreditation_from" => "2017-02-02",
      "phic_accreditation_to" => "2017-02-02",
      "phic_accreditation_no" => "1",
      "status" => "Pending",
      "affiliation_date" => "2017-02-02",
      "code" => "test code"
    }

    # Logic
    {status, result} =
      user.id
      |> FacilityContext.update_step1_facility(facility, params)

    # Assertion
    assert status == :ok
    assert result.license_name == "test"
  end

  test "update_step1_facility with invalid attributes" do
    # Setup
    facility = insert(:facility)
    params = %{}
    user = insert(:user)

    # Logic
    {status, result} =
      FacilityContext.update_step1_facility(user.id, facility, params)

    # Assertion
    assert status == :error
    refute result.valid?
  end

  # update_step2_facility start
  test "update_step2_facility with valid attributes" do
    # Setup
    user = insert(:user, is_admin: true)
    facility = insert(:facility)
    location_group = insert(:location_group)
    params = %{
      "updated_by_id" => user.id,
      "step" => 1,
      "line_1" => "some content",
      "line_2" => "some content",
      "region" => "some content",
      "city" => "some content",
      "province" => "some content",
      "country" => "some content",
      "postal_code" => "some content",
      "latitude" => "some content",
      "longitude" => "some content",
      "location_group_id" => location_group.id
    }

    # Logic
    {status, result} =
      user.id
      |> FacilityContext.update_step2_facility(facility, params)

    # Assertion
    assert status == :ok
    assert result.longitude == "some content"
  end

  test "update_step2_facility with invalid attributes" do
    # Setup
    facility = insert(:facility)
    params = %{}
    user = insert(:user)

    # Logic
    {status, result} =
      user.id
      |> FacilityContext.update_step2_facility(facility, params)

    # Assertion
    assert status == :error
    refute result.valid?
  end

  test "update_step4_facility with valid attributes" do
    # Setup
    user = insert(:user, is_admin: true)
    facility = insert(:facility)
    params = %{
      "tin" => "some content",
      "step" => 1,
      "updated_by_id" => user.id,
      "prescription_term" => "123",
      "credit_term" => "123",
      "credit_limit" => "123",
      "balance_biller" => true,
      "withholding_tax" => "123",
      "authority_to_credit" => true
    }

    # Logic
    {status, result} =
      user.id
      |> FacilityContext.update_step4_facility(facility, params)

    # Assertion
    assert status == :ok
    assert result.tin == "some content"
  end

  test "update_step4_facility with invalid attributes" do
    # Setup
    facility = insert(:facility)
    params = %{}
    user = insert(:user)

    # Logic
    {status, result} =
      user.id
      |> FacilityContext.update_step4_facility(facility, params)

    # Assertion
    assert status == :error
    refute result.valid?
  end

  test "update_step_facility with valid attributes" do
    # Setup
    user = insert(:user, is_admin: true)
    facility = insert(:facility)
    params = %{
      updated_by_id: user.id,
      step: 1,
    }

    # Logic
    {status, result} = FacilityContext.update_step_facility(facility, params)

    # Assertion
    assert status == :ok
    assert result.id == facility.id
  end

  test "update_step_facility with invalid attributes" do
    # Setup
    facility = insert(:facility)
    params = %{}

    # Logic
    {status, result} = FacilityContext.update_step_facility(facility, params)

    # Assertion
    assert status == :error
    refute result.valid?
  end

  # test "get_all_facility return with 3 values"  do
  #   # Setup
  #   insert(:facility, name: "test provider 2")
  #   insert(:facility, name: "test provider 1")
  #   insert(:facility, name: "test provider 3")

  #   # Logic
  #   result = FacilityContext.get_all_facility()

  #   # Assertion
  #   assert Enum.count(result) == 3
  # end

  test "get_facility! return with the given id" do
    # Setup
    facility =
      :facility
      |> insert(name: "test provider 2", loa_condition: true)
      |> Repo.preload([
        :facility_files,
        :facility_service_fees,
        [practitioner_facilities: [
          :practitioner_status,
          :practitioner_schedules,
          practitioner:  [
            practitioner_specializations: :specialization
          ]
        ]
        ],
        [facility_location_groups: :location_group]
      ])
      # Logic
    result = FacilityContext.get_facility!(facility.id)

    # Assertion
    assert result == facility
  end

  test "get_all_facility_contacts return with 1 value" do
    facility = insert(:facility)
    contact = insert(:contact)
    facility_contact = insert(:facility_contact,
                              facility: facility,
                              contact: contact)

    result = FacilityContext.get_all_facility_contacts(facility.id)

    assert Enum.count(result) == Enum.count([facility_contact])
  end

  test "get_facility_by_contact_id return with the given id" do
    facility = insert(:facility)
    contact = insert(:contact)
    facility_contact = insert(:facility_contact,
                              facility: facility,
                              contact: contact)

    result = FacilityContext.get_facility_by_contact_id(contact.id)

    assert result.id == facility_contact.facility_id
  end

  test "get_facility_payor_procedure! return with the 1 value" do
    fpp = insert(:facility_payor_procedure)

    result = FacilityContext.get_facility_payor_procedure!(fpp.id)

    assert result.id == fpp.id
  end

  test "get_all_facility_payor_procedures returns all fpp" do
    fpp = insert(:facility_payor_procedure)
    fpps = FacilityContext.get_all_facility_payor_procedures(fpp.facility_id)
    assert fpp.id == Enum.at(fpps, 0).id
  end

  test "get_all_facility_payor_procedures! return with the 1 value" do
    facility = insert(:facility)
    payor_procedure = insert(:payor_procedure)
    fpp =
      :facility_payor_procedure
      |> insert(
        code: "code",
        name: "name",
        facility: facility,
        payor_procedure: payor_procedure
      )

    [result] = FacilityContext.get_all_facility_payor_procedures(facility.id)

    assert result.id == fpp.id
  end

  test "get_all_facility_payor_procedures! return empty" do
    facility = insert(:facility)
    insert(:payor_procedure)
    insert(:facility_payor_procedure, code: "code", name: "name")

    result = FacilityContext.get_all_facility_payor_procedures(facility.id)

    assert Enum.empty?(result)
  end

  test "get_fpayor_procedure_id_and_code return with the given value" do
    facility = insert(:facility)
    payor_procedure = insert(:payor_procedure)
    fpp =
      :facility_payor_procedure
      |> insert(
        code: "code",
        name: "name",
        facility: facility,
        payor_procedure: payor_procedure
      )

    [result] = FacilityContext.get_fpayor_procedure_id_and_code(facility.id)

    assert result.code == fpp.code
    assert result.payor_procedure_id == fpp.payor_procedure_id
  end

  test "get_fpayor_procedure_id_and_code return empty" do
    facility = insert(:facility)
    payor_procedure = insert(:payor_procedure)

    :facility_payor_procedure
    |> insert(
      code: "code",
      name: "name",
      payor_procedure: payor_procedure
    )

    result  = FacilityContext.get_fpayor_procedure_id_and_code(facility.id)

    assert Enum.empty?(result)
  end

  test "check_all_facility_payor_procedures return with the given value" do
    facility = insert(:facility)
    payor_procedure =
      :payor_procedure
      |> insert(code: "code", description: "Test")

    :facility_payor_procedure
    |> insert(
      code: "code",
      name: "name",
      facility: facility,
      payor_procedure: payor_procedure
    )

    [result] = FacilityContext.check_all_facility_payor_procedures(facility.id)

    assert result ==
      {
        "#{payor_procedure.code}/#{payor_procedure.description}",
        "#{payor_procedure.id}"
      }
  end

  test "check_all_facility_payor_procedures return empty" do
    facility = insert(:facility)
    payor_procedure =
      :payor_procedure
      |> insert(code: "code", description: "Test")

    :facility_payor_procedure
    |> insert(code: "code", name: "name", payor_procedure: payor_procedure)

    result = FacilityContext.check_all_facility_payor_procedures(facility.id)

    assert Enum.empty?(result)
  end

  test "create_facility_payor_procedure! with valid attrs" do
    facility = insert(:facility)
    payor_procedure =
      insert(:payor_procedure, code: "code", description: "Test")
    params = %{
      code: "code",
      amount: 123,
      name: "name",
      start_date: Ecto.Date.cast!("2017-01-10"),
      payor_procedure_id: payor_procedure.id,
      facility_id: facility.id
    }
    {:ok, result} = FacilityContext.create_facility_payor_procedure!(params)

    assert result.code == params.code
  end

  test "create_facility_payor_procedure! with invalid attrs" do
    {:error, %Ecto.Changeset{}} =
      FacilityContext.create_facility_payor_procedure!(%{})
  end

  test "update_facility_payor_procedure! with valid attrs" do
    facility = insert(:facility)
    payor_procedure =
      insert(:payor_procedure, code: "code", description: "Test")
    fpp =
      :facility_payor_procedure
      |> insert(facility: facility, payor_procedure: payor_procedure)
    params = %{
      code: "code",
      amount: 123,
      name: "name",
      start_date: Ecto.Date.cast!("2017-01-10"),
      payor_procedure_id: payor_procedure.id,
      facility_id: facility.id
    }
    {:ok, result} =
      FacilityContext.update_facility_payor_procedure!(fpp, params)

    assert result.code == params.code
  end

  test "create_facility_payor_procedure_room create many fppr" do
    facility = insert(:facility)
    payor_procedure = insert(:payor_procedure)
    facility_payor_procedure =
      :facility_payor_procedure
      |> insert(payor_procedure: payor_procedure, facility: facility)
    facility_room_rate =
      insert(:facility_room_rate)
    room_params = [
      facility_room_rate.id,
       1235,
       35,
       Ecto.Date.cast!("2017-08-10")
      ]
    assert {:ok, _room_params_inserted} =
      FacilityContext.create_many_facility_payor_procedure_room(
        room_params,
        facility_payor_procedure.id
      )
  end

  test "delete_facility_payor_procedure_room deletes all fppr" do
    facility = insert(:facility)
    payor_procedure = insert(:payor_procedure)
    facility_payor_procedure =
      :facility_payor_procedure
      |> insert(payor_procedure: payor_procedure, facility: facility)
    facility_room_rate = insert(:facility_room_rate)

    :facility_payor_procedure_room
    |> insert(
      facility_payor_procedure: facility_payor_procedure,
      facility_room_rate: facility_room_rate
    )

    assert {:ok, "deleted_all"} ==
      FacilityContext.delete_facility_payor_procedure_room(
        facility_payor_procedure.id
      )
  end

  test "change_facility_payor_procedure/1 returns a FPP changeset" do
    fpp = insert(:facility_payor_procedure)
    assert %Ecto.Changeset{} =
      FacilityContext.change_facility_payor_procedure(fpp)
  end

  test "get_facility_by_code! returns the facility with given code" do
    facility = insert(:facility, code: "Sample", loa_condition: true)
    assert FacilityContext.get_facility_by_code(facility.code) == facility
  end

  test "insert_or_update_facility * validates facility" do
    facility = insert(:facility, code: "Sample")
    type = insert(:dropdown, type: "Facility Type")
    category = insert(:dropdown, type: "Facility Category")
    user = insert(:user, is_admin: true)
    get_facility = FacilityContext.get_facility_by_code(facility.code)

    if is_nil(get_facility) do
      params = %{
        ftype_id: type.id,
        fcategory_id: category.id,
        created_by_id: user.id,
        updated_by_id: user.id,
        step: 1,
        name: "Test provider 1",
        license_name: "test",
        phic_accreditation_from: Ecto.Date.utc,
        phic_accreditation_to: Ecto.Date.utc,
        phic_accreditation_no: "1",
        status: "Affiliated",
        affiliation_date: Ecto.Date.utc,
        disaffiliation_date: Ecto.Date.utc
      }

      # Logic
      {status, facility} = FacilityContext.create_facility(user.id, params)
      # Assertion
      assert status == :ok
      assert facility.name == "Test provider 1"
    else
      params = %{
        updated_by_id: user.id,
        step: 1,
      }

      # Logic
      {status, result} = FacilityContext.update_step_facility(facility, params)

      # Assertion
      assert status == :ok
      assert result.id == facility.id
    end
  end

  test "get_facility_by_member_id with valid member id" do
    member = insert(:member)
    account = insert(:account)
    product = insert(:product)
    facility = insert(:facility, name: "test", step: 7, status: "Affiliated")
    coverage = insert(:coverage)
    account_product = insert(:account_product,
                              account: account,
                              product: product)
    insert(:member_product,
            member: member,
            account_product: account_product)
    product_coverage = insert(:product_coverage,
                              product: product,
                              coverage: coverage,
                              type: "inclusion")
    insert(:product_coverage_facility,
           facility: facility,
           product_coverage: product_coverage)

    result = FacilityContext.get_facility_by_member_id(member.id)

    assert length(result) == 1
  end

  test "get_facility_by_member_id with invalid member id" do
    result = FacilityContext.get_facility_by_member_id(UUID.generate)

    assert length(result) == 0
  end

  test "search_facilities with code only criteria" do
    category =
      :dropdown
      |> insert(
        type: "Facility Category",
        text: "TERTIARY",
        value: "TER"
      )

    type =
      :dropdown
      |> insert(
        type: "Facility Type",
        text: "CLINIC-BASED",
        value: "CLINIC"
      )

    facility1 =
      :facility
      |> insert(
        code: "10001",
        category: category,
        type: type,
        city: "Makati",
        line_1: "edsa",
        line_2: "",
        province: "Metro Manila",
        status: "Affiliated",
        step: 7
      )

    param =
      %{
        "code" => "10001",
        "city" => "",
        "address" => "",
        "province" => "",
        "type" => "",
        "status" => ""
      }

    result =
      param
      |> FacilityContext.search_facilities()

    assert result == [
      %{
        "id" => facility1.id,
        "code" => facility1.code,
        "name" => facility1.name,
        "type" => type.text,
        "category" => category.text,
        "line_1" => facility1.line_1,
        "line_2" => facility1.line_2,
        "city" => facility1.city,
        "province" => facility1.province,
        "region" => facility1.region,
        "country" => facility1.country,
        "postal_code" => facility1.postal_code,
        "phone_no" => facility1.phone_no,
        "latitude" => facility1.latitude,
        "longitude" => facility1.longitude
      }
    ]
  end

  test "search_facilities with address only criteria" do
    category =
      :dropdown
      |> insert(
        type: "Facility Category",
        text: "TERTIARY",
        value: "TER"
      )

    type =
      :dropdown
      |> insert(
        type: "Facility Type",
        text: "CLINIC-BASED",
        value: "CLINIC"
      )

    facility1 =
      :facility
      |> insert(
        code: "10001",
        category: category,
        type: type,
        city: "Makati",
        line_1: "edsa",
        line_2: "",
        province: "Metro Manila",
        status: "Affiliated",
        step: 7
      )

    param =
      %{
        "code" => "",
        "city" => "",
        "address" => "edsa",
        "province" => "",
        "type" => "",
        "status" => ""
      }

    result =
      param
      |> FacilityContext.search_facilities()

    assert result == [
      %{
        "id" => facility1.id,
        "code" => facility1.code,
        "name" => facility1.name,
        "type" => type.text,
        "category" => category.text,
        "line_1" => facility1.line_1,
        "line_2" => facility1.line_2,
        "city" => facility1.city,
        "province" => facility1.province,
        "region" => facility1.region,
        "country" => facility1.country,
        "postal_code" => facility1.postal_code,
        "phone_no" => facility1.phone_no,
        "latitude" => facility1.latitude,
        "longitude" => facility1.longitude
      }
    ]
  end

  test "search_facilities with city only criteria" do
    category =
      :dropdown
      |> insert(
        type: "Facility Category",
        text: "TERTIARY",
        value: "TER"
      )

    type =
      :dropdown
      |> insert(
        type: "Facility Type",
        text: "CLINIC-BASED",
        value: "CLINIC"
      )

    facility1 =
      :facility
      |> insert(
        code: "10001",
        category: category,
        type: type,
        city: "Makati",
        line_1: "edsa",
        line_2: "",
        province: "Metro Manila",
        status: "Affiliated",
        step: 7
      )

    param =
      %{
        "code" => "",
        "city" => "Makati",
        "address" => "",
        "province" => "",
        "type" => "",
        "status" => ""
      }

    result =
      param
      |> FacilityContext.search_facilities()

    assert result == [
      %{
        "id" => facility1.id,
        "code" => facility1.code,
        "name" => facility1.name,
        "type" => type.text,
        "category" => category.text,
        "line_1" => facility1.line_1,
        "line_2" => facility1.line_2,
        "city" => facility1.city,
        "province" => facility1.province,
        "region" => facility1.region,
        "country" => facility1.country,
        "postal_code" => facility1.postal_code,
        "phone_no" => facility1.phone_no,
        "latitude" => facility1.latitude,
        "longitude" => facility1.longitude
      }
    ]
  end

  test "search_facilities with province only criteria" do
    category =
      :dropdown
      |> insert(
        type: "Facility Category",
        text: "TERTIARY",
        value: "TER"
      )

    type =
      :dropdown
      |> insert(
        type: "Facility Type",
        text: "CLINIC-BASED",
        value: "CLINIC"
      )

    facility1 =
      :facility
      |> insert(
        code: "10001",
        category: category,
        type: type,
        city: "Makati",
        line_1: "edsa",
        line_2: "",
        province: "Metro Manila",
        status: "Affiliated",
        step: 7
      )

    param =
      %{
        "code" => "",
        "city" => "",
        "address" => "",
        "province" => "Metro Manila",
        "type" => "",
        "status" => ""
      }

    result =
      param
      |> FacilityContext.search_facilities()

    assert result == [
      %{
        "id" => facility1.id,
        "code" => facility1.code,
        "name" => facility1.name,
        "type" => type.text,
        "category" => category.text,
        "line_1" => facility1.line_1,
        "line_2" => facility1.line_2,
        "city" => facility1.city,
        "province" => facility1.province,
        "region" => facility1.region,
        "country" => facility1.country,
        "postal_code" => facility1.postal_code,
        "phone_no" => facility1.phone_no,
        "latitude" => facility1.latitude,
        "longitude" => facility1.longitude
      }
    ]
  end

  test "search_facilities with type only criteria" do
    category =
      :dropdown
      |> insert(
        type: "Facility Category",
        text: "TERTIARY",
        value: "TER"
      )

    type =
      :dropdown
      |> insert(
        type: "Facility Type",
        text: "CLINIC-BASED",
        value: "CLINIC"
      )

    facility1 =
      :facility
      |> insert(
        code: "10001",
        category: category,
        type: type,
        city: "Makati",
        line_1: "edsa",
        line_2: "",
        province: "Metro Manila",
        status: "Affiliated",
        step: 7
      )

    param =
      %{
        "code" => "",
        "city" => "",
        "address" => "",
        "province" => "",
        "type" => type.id,
        "status" => ""
      }

    result =
      param
      |> FacilityContext.search_facilities()

    assert result == [
      %{
        "id" => facility1.id,
        "code" => facility1.code,
        "name" => facility1.name,
        "type" => type.text,
        "category" => category.text,
        "line_1" => facility1.line_1,
        "line_2" => facility1.line_2,
        "city" => facility1.city,
        "province" => facility1.province,
        "region" => facility1.region,
        "country" => facility1.country,
        "postal_code" => facility1.postal_code,
        "phone_no" => facility1.phone_no,
        "latitude" => facility1.latitude,
        "longitude" => facility1.longitude
      }
    ]
  end

  test "search_facilities with status only criteria" do
    category =
      :dropdown
      |> insert(
        type: "Facility Category",
        text: "TERTIARY",
        value: "TER"
      )

    type =
      :dropdown
      |> insert(
        type: "Facility Type",
        text: "CLINIC-BASED",
        value: "CLINIC"
      )

    facility1 =
      :facility
      |> insert(
        code: "10001",
        category: category,
        type: type,
        city: "Makati",
        line_1: "edsa",
        line_2: "",
        province: "Metro Manila",
        status: "Affiliated",
        step: 7
      )

    param =
      %{
        "code" => "",
        "city" => "",
        "address" => "",
        "province" => "",
        "type" => "",
        "status" => "Affiliated"
      }

    result =
      param
      |> FacilityContext.search_facilities()

    assert result == [
      %{
        "id" => facility1.id,
        "code" => facility1.code,
        "name" => facility1.name,
        "type" => type.text,
        "category" => category.text,
        "line_1" => facility1.line_1,
        "line_2" => facility1.line_2,
        "city" => facility1.city,
        "province" => facility1.province,
        "region" => facility1.region,
        "country" => facility1.country,
        "postal_code" => facility1.postal_code,
        "phone_no" => facility1.phone_no,
        "latitude" => facility1.latitude,
        "longitude" => facility1.longitude
      }
    ]
  end

  test "search_facilities with all search criteria" do
    category =
      :dropdown
      |> insert(
        type: "Facility Category",
        text: "TERTIARY",
        value: "TER"
      )

    type =
      :dropdown
      |> insert(
        type: "Facility Type",
        text: "CLINIC-BASED",
        value: "CLINIC"
      )

    facility1 =
      :facility
      |> insert(
        code: "10001",
        category: category,
        type: type,
        city: "Makati",
        line_1: "edsa",
        line_2: "",
        province: "Metro Manila",
        status: "Affiliated",
        step: 7
      )

    param =
      %{
        "code" => "10001",
        "city" => "Makati",
        "address" => "edsa",
        "province" => "Metro Manila",
        "type" => type.id,
        "status" => "Affiliated"
      }

    result =
      param
      |> FacilityContext.search_facilities()

    assert result == [
      %{
        "id" => facility1.id,
        "code" => facility1.code,
        "name" => facility1.name,
        "type" => type.text,
        "category" => category.text,
        "line_1" => facility1.line_1,
        "line_2" => facility1.line_2,
        "city" => facility1.city,
        "province" => facility1.province,
        "region" => facility1.region,
        "country" => facility1.country,
        "postal_code" => facility1.postal_code,
        "phone_no" => facility1.phone_no,
        "latitude" => facility1.latitude,
        "longitude" => facility1.longitude
      }
    ]
  end

  test "search_facilities with multiple return" do
    category =
      :dropdown
      |> insert(
        type: "Facility Category",
        text: "TERTIARY",
        value: "TER"
      )

    type =
      :dropdown
      |> insert(
        type: "Facility Type",
        text: "CLINIC-BASED",
        value: "CLINIC"
      )

    :facility
    |> insert(
      code: "10001",
      category: category,
      type: type,
      city: "Makati",
      line_1: "edsa",
      line_2: "",
      province: "Metro Manila",
      status: "Affiliated",
      step: 7
    )

    :facility
    |> insert(
      code: "10002",
      category: category,
      type: type,
      city: "Makati",
      line_1: "",
      line_2: "edsa",
      province: "Metro Manila",
      status: "Affiliated",
      step: 7
    )

    param =
      %{
        "code" => "",
        "city" => "Makati",
        "address" => "edsa",
        "province" => "Metro Manila",
        "type" => type.id,
        "status" => ""
      }

    result =
      param
      |> FacilityContext.search_facilities()

    assert length(result) == 2
  end

  test "search_facilities with no return" do
    category =
      :dropdown
      |> insert(
        type: "Facility Category",
        text: "TERTIARY",
        value: "TER"
      )

    type =
      :dropdown
      |> insert(
        type: "Facility Type",
        text: "CLINIC-BASED",
        value: "CLINIC"
      )

    :facility
    |> insert(
      code: "10001",
      category: category,
      type: type,
      city: "Makati",
      line_1: "edsa",
      line_2: "",
      province: "Metro Manila",
      status: "Affiliated",
      step: 6
    )

    param =
      %{
        "code" => "10001",
        "city" => "Makati",
        "address" => "edsa",
        "province" => "Metro Manila",
        "type" => type.id,
        "status" => "Affiliated"
      }

    result =
      param
      |> FacilityContext.search_facilities()

    assert length(result) == 0
  end

  test "get facility payor procedure with valid data" do
    payor_procedure = insert(:payor_procedure)
    facility = insert(:facility)

    :facility_payor_procedure
    |> insert(payor_procedure: payor_procedure, facility: facility)

    result = FacilityContext.get_fpp(payor_procedure.id, facility.id)

    assert result.payor_procedure_id == payor_procedure.id
    assert result.facility_id == facility.id
  end

  test "get facility payor procedure with invalid data" do
    payor_procedure = insert(:payor_procedure)
    facility = insert(:facility)

    result = FacilityContext.get_fpp(payor_procedure.id, facility.id)

    assert is_nil(result)
  end

  test "fpp_csv_download/2, csv export for facility payor procedure" do
    facility = insert(:facility)
    room = insert(:room, code: "PrivRoom")
    facility_room_rate =
      insert(:facility_room_rate, facility: facility, room: room)
    payor_procedure =
      insert(:payor_procedure, description: "pp", code: "pp101")
    fpp =
      :facility_payor_procedure
      |> insert(
        facility: facility,
        payor_procedure: payor_procedure,
        name: "fpp_cmc_desc",
        amount: 20.20,
        start_date: Ecto.Date.cast!("2017-10-04"),
        code: "fpp101"
      )

    :facility_payor_procedure_room
    |> insert(
      facility_payor_procedure: fpp,
      facility_room_rate: facility_room_rate,
      amount: 1200.50,
      discount: 10,
      start_date: Ecto.Date.cast!("2017-10-04")
    )

    search_pp_code = %{
      "search_value" => "pp10"
    }

    search_pp_desc = %{
      "search_value" => "pp"
    }

    search_fpp_code = %{
      "search_value" => "fpp10"
    }

    search_fpp_name = %{
      "search_value" => "fpp_"
    }

    search_room = %{
      "search_value" => "privroom"
    }

    search_amount = %{
      "search_value" => "1200.5"
    }

    search_discount = %{
      "search_value" => 10
    }

    search_by_date = %{
      "search_value" => "2017-10-04"
    }

    result = [[
      "pp101",
      "pp",
      "fpp101",
      "fpp_cmc_desc",
      "PrivRoom",
      Decimal.new(1200.5),
      Decimal.new(10),
      Ecto.Date.cast!("2017-10-04")
    ]]

    assert FacilityContext.fpp_csv_download(search_pp_code, facility.id) ==
      result
    assert FacilityContext.fpp_csv_download(search_pp_desc, facility.id) ==
      result
    assert FacilityContext.fpp_csv_download(search_fpp_code, facility.id) ==
      result
    assert FacilityContext.fpp_csv_download(search_fpp_name, facility.id) ==
      result
    assert FacilityContext.fpp_csv_download(search_room, facility.id) ==
      result
    assert FacilityContext.fpp_csv_download(search_amount, facility.id) ==
      result
    assert FacilityContext.fpp_csv_download(search_discount, facility.id) ==
      result
    assert FacilityContext.fpp_csv_download(search_by_date, facility.id) ==
      result

  end

  test "get_batch_log/2, csv export/download for success and error in batch" do
    insert(:facility)
    facility_payor_procedure_upload_file =
      insert(:facility_payor_procedure_upload_file)

    :facility_payor_procedure_upload_log
    |> insert(
      facility_payor_procedure_upload_file:
        facility_payor_procedure_upload_file,
      status: "success",
      room_code: "Testroom",
      start_date: Ecto.Date.cast!("2017-10-04"),
      remarks: "ok",
      discount: Decimal.new(100.55),
      amount: 1200.55,
      provider_cpt_code: "CMC101",
      provider_cpt_name: "CMCfpp",
      payor_cpt_code: "PYOR101",
      payor_cpt_name: "PYORpp"
    )

    assert FacilityContext.get_batch_log(
      facility_payor_procedure_upload_file.id, "success")
      ==
        [["PYOR101", "CMC101", "CMCfpp",
          "Testroom", Decimal.new(1200.55),
          Decimal.new(100.55), "10/04/2017", "ok"]]
  end

  test "get_all_facility_code with return values" do
    insert(:facility, code: "test")
    result = FacilityContext.get_all_facility_code()
    assert length(result) == 1
  end

  test "get_all_facility_code with no value" do
    result = FacilityContext.get_all_facility_code()
    assert length(result) == 0
  end

  test "get facility payor procedure (get_fpp) with valid data" do
    payor_procedure = insert(:payor_procedure)
    facility = insert(:facility)

    :facility_payor_procedure
    |> insert(facility: facility, payor_procedure: payor_procedure)

    result = FacilityContext.get_fpp(payor_procedure.id, facility.id)
    assert result.facility_id == facility.id
    assert result.payor_procedure_id == payor_procedure.id
  end

  test "get facility payor procedure (get_fpp) with invalid data" do
    payor_procedure = insert(:payor_procedure)
    facility = insert(:facility)

    result = FacilityContext.get_fpp(payor_procedure.id, facility.id)

    assert is_nil(result)
  end

  test "create facility payor procedure upload file with valid attrs" do
    facility = insert(:facility)
    user = insert(:user)
    params = %{
      facility_id: facility.id,
      batch_no: "9999",
      filename: "File.csv",
      remarks: "ok",
      created_by_id: user.id
    }

    {:ok, result} = FacilityContext.create_fpp_upload_file(params)

    assert result.facility_id == facility.id
    assert result.created_by_id == user.id
  end

  test "create facility payor procedure upload file with invalid attrs" do
    assert {:error, _changeset} = FacilityContext.create_fpp_upload_file(%{})
  end

  test "create facility payor procedure log with valid attrs" do
    user = insert(:user)
    fppuf = insert(:facility_payor_procedure_upload_file)
    params = %{
      amount: "120",
      created_by_id: user.id,
      discount: "120",
      facility_payor_procedure_upload_file_id: fppuf.id,
      filename: "FPPTemplate.csv",
      payor_cpt_code: "S2196",
      payor_cpt_name: "(ACP) ACID PHOSPHATASE",
      provider_cpt_code: "ProvCPTCode-01",
      provider_cpt_name: "ProvCPTCode-Desc-01",
      remarks: "ok",
      room_code: "PRIVROOM101",
      start_date: "2017-10-06",
      status: "success"
    }
    {:ok, result} = FacilityContext.create_fpp_upload_log(params)

    assert result.facility_payor_procedure_upload_file_id == fppuf.id
  end

  test "get fpp upload logs (get_fpp_upload_logs) with valid data" do
    facility = insert(:facility)
    fppuf =
      :facility_payor_procedure_upload_file
      |> insert(facility: facility)
      |> Map.drop([:facility, :facility_payor_procedure_upload_logs])

    :facility_payor_procedure_upload_log
    |> insert(facility_payor_procedure_upload_file: fppuf)

    result =
      facility.id
      |> FacilityContext.get_fpp_upload_logs()
      |> Enum.at(0)
      |> Map.drop([:facility, :facility_payor_procedure_upload_logs])

    assert result == fppuf
  end

  test "get fpp upload logs (get_fpp_upload_logs) with invalid data" do
    facility = insert(:facility)
    result = FacilityContext.get_fpp_upload_logs(facility.id)

    assert Enum.empty?(result)
  end

  test "get facility payor procedure upload logs by type success" do
    facility = insert(:facility)
    fppuf = insert(:facility_payor_procedure_upload_file, facility: facility)

    :facility_payor_procedure_upload_log
    |> insert(facility_payor_procedure_upload_file: fppuf, status: "success")

    result = FacilityContext.get_fpp_upload_logs_by_type(fppuf.id, "success")

    refute Enum.empty?(result)
  end

  test "get facility payor procedure upload logs by type failed" do
    facility = insert(:facility)
    fppuf = insert(:facility_payor_procedure_upload_file, facility: facility)

    :facility_payor_procedure_upload_log
    |> insert(facility_payor_procedure_upload_file: fppuf, status: "failed")

    result = FacilityContext.get_fpp_upload_logs_by_type(fppuf.id, "failed")

    refute Enum.empty?(result)
  end

  test "generate batch no" do
    facility = insert(:facility)

    result = FacilityContext.generate_batch_no(facility.id, 1)

    assert result == "0001"
  end

  test "create facility payor procedure room with valid attrs" do
    fpp = insert(:facility_payor_procedure)
    frr = insert(:facility_room_rate)
    params = %{
      amount: "450",
      discount: "120",
      facility_payor_procedure_id: fpp.id,
      facility_room_rate_id: frr.id,
      start_date: "2017-10-06"
    }

    {:ok, result} = FacilityContext.create_facility_payor_procedure_room(params)
    assert result.facility_payor_procedure_id == fpp.id
    assert result.facility_room_rate_id == frr.id
  end

  test "create facility payor procedure room with invalid attrs" do
    assert {:error, _result} =
      FacilityContext.create_facility_payor_procedure_room(%{})
  end

  test "get facility room rate by code with valid data returns a struct" do
    facility = insert(:facility)
    room = insert(:room, code: "code101")
    frr =  insert(:facility_room_rate, facility: facility, room: room)

    result =
      FacilityContext.get_facility_room_rate_by_code(facility.id, "code101")

    assert Map.drop(result, [:facility, :room]) ==
      Map.drop(frr, [:facility, :room])
  end

  test "get facility room rate by code with invalid data returns error" do
    facility = insert(:facility)
    assert {:not_found} =
      FacilityContext.get_facility_room_rate_by_code(facility.id, "code101")
  end

  test "get facility room rate by id with valid data" do
    facility = insert(:facility)
    pp = insert(:payor_procedure)
    fpp =
      insert(:facility_payor_procedure, payor_procedure: pp, facility: facility)
    frr = insert(:facility_room_rate)

    :facility_payor_procedure_room
    |> insert(facility_payor_procedure: fpp, facility_room_rate: frr)

    result =
      FacilityContext.get_facility_room_rate_by_id(frr.id, pp.id, facility.id)

    assert result.facility_payor_procedure_id == fpp.id
    assert result.facility_room_rate_id == frr.id
  end

  test "get facility room rate by id with invalid data" do
    facility = insert(:facility)
    pp = insert(:payor_procedure)
    frr = insert(:facility_room_rate)

    assert {:room_not_found} =
      FacilityContext.get_facility_room_rate_by_id(frr.id, pp.id, facility.id)
  end

  test "delete facility payor procedure returns nil" do
    pp = insert(:payor_procedure)
    fpp = insert(:facility_payor_procedure, payor_procedure: pp)
    frr = insert(:facility_room_rate)

    :facility_payor_procedure_room
    |> insert(facility_payor_procedure: fpp, facility_room_rate: frr)

    assert {:ok, _facility_payor_procedure} =
      FacilityContext.delete_facility_payor_procedure(fpp.id)
  end

  test "delete facility payor procedure return a struct" do
    pp = insert(:payor_procedure)
    fpp = insert(:facility_payor_procedure, payor_procedure: pp)

    {:ok, result} = FacilityContext.delete_facility_payor_procedure(fpp.id)

    assert result.id == fpp.id
  end

  test "insert_facility_file/1 returns ok when data is valid" do
    file = insert(:file)
    facility = insert(:facility)
    params = %{
      facility_id: facility.id,
      file_id: file.id,
      type: "some type"
    }
    assert {:ok, _facility_file} = FacilityContext.insert_facility_file(params)
  end

  test "insert_facility_file/1 returns errors when data is invalid" do
    file = insert(:file)
    facility = insert(:facility)
    params = %{
      facility_id: facility.id,
      file_id: file.id,
    }
    assert {:error, _changeset} = FacilityContext.insert_facility_file(params)
  end

  test "delete_facility_file/1 returns ok when data is valid" do
    facility_file = insert(:facility_file)
    assert {:ok, _deleted_file} =
      FacilityContext.delete_facility_file(facility_file.file.id)
  end

  test "get_all_completed_facility return multiple records" do
    type = insert(:dropdown, type: "Facility Type")
    category = insert(:dropdown, type: "Facility Category")

    :facility
    |> insert(
      code: "1",
      step: 7,
      type: type,
      category: category,
      status: "Affiliated"
    )

    :facility
    |> insert(
      code: "2",
      step: 7,
      type: type,
      category: category,
      status: "Affiliated"
    )

    :facility
    |> insert(
      code: "3",
      step: 7,
      type: type,
      category: category,
      status: "Affiliated"
    )

    :facility
    |> insert(
      code: "4",
      step: 7,
      type: type,
      category: category
    )

    result = FacilityContext.get_all_completed_facility()

    assert length(result) == 4
  end

  test "get_all_completed_facility return records" do
    type = insert(:dropdown, type: "Facility Type")
    category = insert(:dropdown, type: "Facility Category")
    insert(:facility, code: "1", step: 7, type: type, category: category)
    insert(:facility, code: "2", step: 7, type: type, category: category)
    insert(:facility, code: "3", step: 7, type: type, category: category)
    insert(:facility, code: "4", step: 7, type: type, category: category)

    result = FacilityContext.get_all_completed_facility()

    assert length(result) == 4
  end

  test "get_all_facility_ruvs return with 1 value" do
    facility = insert(:facility)
    ruv = insert(:ruv)
    facility_ruv = insert(:facility_ruv,
                              facility: facility,
                              ruv: ruv)

    result = FacilityContext.get_all_facility_ruv(facility.id)

    assert Enum.count(result) == Enum.count([facility_ruv])
  end

  test "set_facility_ruv/1 returns ok when data is valid" do
    ruv = insert(:ruv)
    facility = insert(:facility)
    params = %{
      facility_id: facility.id,
      ruv_id: ruv.id,
      effectivity_date: Ecto.Date.cast!("2017-10-04")
    }
    assert {:ok, _facility_ruv} = FacilityContext.set_facility_ruv(params)
  end

  test "create_facility_service_fee/1 inserts facility service fee when params are valid" do
    facility = insert(:facility)
    service_type = insert(:dropdown, text: "Fixed Fee", value: "Fixed Fee")
    coverage = insert(:coverage)
    params = %{
      "coverage_id" => coverage.id,
      "service_type_id" => service_type.id,
      "payment_mode" => "Individual",
      "rate" => "123",
      "facility_id" => facility.id
    }
    assert {:ok, fss} = FacilityContext.create_facility_service_fee(params)
    assert Decimal.to_integer(fss.rate_fixed) == 123
  end

  test "create_facility_service123_fee/1 inserts facility service fee when params are valid" do
    insert(:facility)
    service_type = insert(:dropdown, text: "Fixed Fee", value: "Fixed Fee")
    coverage = insert(:coverage)
    params = %{
      "coverage_id" => coverage.id,
      "service_type_id" => service_type.id,
    }
    assert {:error, _changeset} =
      FacilityContext.create_facility_service_fee(params)
  end

  test "fr_csv_download/2, csv export for facility payor procedure" do
    facility = insert(:facility)
    ruv =
    :ruv
    |> insert(
      description: "ruv_description",
      code: "ruv_code",
      type: "ruv_type",
      value: Decimal.new(10),
      effectivity_date: Ecto.Date.cast!("2017-10-04")
    )
    insert(:facility_ruv, facility: facility, ruv: ruv)
    search_code = %{
      "search_value" => "ruv_code"
    }

    search_description = %{
      "search_value" => "ruv_description"
    }

    search_type = %{
      "search_value" => "ruv_type"
    }

    search_value = %{
      "search_value" => "10"
    }

    search_by_date = %{
      "search_value" => "2017-10-04"
    }

    result =
      [["ruv_code",
        "ruv_description",
        "ruv_type",
        Decimal.new(10),
        "10/04/2017"
      ]]
    assert FacilityContext.fr_csv_download(search_code, facility.id) == result
    assert FacilityContext.fr_csv_download(search_description, facility.id) ==
      result
    assert FacilityContext.fr_csv_download(search_type, facility.id) == result
    assert FacilityContext.fr_csv_download(search_value, facility.id) == result
    assert FacilityContext.fr_csv_download(search_by_date, facility.id) ==
      result

  end

  test "get_ruv_batch_log/2, csv export/download for success and error in batch" do
    insert(:facility)
    facility_ruv_upload_file = insert(:facility_ruv_upload_file)
    insert(:facility_ruv_upload_log,
           facility_ruv_upload_file: facility_ruv_upload_file,
           status: "success",
           effectivity_date: Ecto.Date.cast!("2017-10-04"),
           remarks: "ok",
           value: Decimal.new(100.55),
           ruv_code: "ruv_code",
           ruv_description: "ruv_description",
           ruv_type: "ruv_type"
    )

    assert FacilityContext.get_ruv_batch_log(
      facility_ruv_upload_file.id, "success")
      == [[
        "ruv_code", "ruv_description",
        "ruv_type", Decimal.new(100.55), "10/04/2017", "ok"]]
  end

  test "get_facility_by_long_lat with return" do
    facility =
      :facility
      |> insert(
        longitude: "123.1213",
        latitude: "1213.12131",
        step: "7"
      )

    params = %{
      "latitude" => "1213.12131",
      "longitude" => "123.1213"
    }

    [result] =
      params
      |> FacilityContext.get_facility_by_long_lat(UUID.generate())

    assert result.id == facility.id
    assert result.latitude == facility.latitude
    assert result.longitude == facility.longitude
  end

  test "get_facility_by_long_lat without return" do
    facility =
      :facility
      |> insert(
        longitude: "123.1213",
        latitude: "1213.12131",
        step: "7"
      )

    params = %{
      "latitude" => "1213.12131",
      "longitude" => "123.1213"
    }

    result =
      params
      |> FacilityContext.get_facility_by_long_lat(facility.id)

    assert result == []
  end

  test "insert_facility_location_group with valid params" do
    facility =
      :facility
      |> insert()

    location_group =
      :location_group
      |> insert()

    params = %{
      facility_id: facility.id,
      location_group_id: location_group.id
    }

    {status, result} =
      params
      |> FacilityContext.insert_facility_location_group()

    assert result.facility_id == facility.id
    assert status == :ok
  end

  test "insert_facility_location_group with invalid params" do
    facility =
      :facility
      |> insert()

    params = %{
      facility_id: facility.id
    }

    {status, changeset} =
      params
      |> FacilityContext.insert_facility_location_group()

    refute changeset.valid?
    assert status == :error
  end

  test "delete_facility_location_groups with existing facility" do
    location_group =
      :location_group
      |> insert()

    facility =
      :facility
      |> insert()

    :facility_location_group
    |> insert(
      facility: facility,
      location_group: location_group
    )

    {result, _} =
      facility
      |> FacilityContext.delete_facility_location_groups

    assert result == 1
  end

  test "delete_facility_location_groups without facility" do
    location_group =
      :location_group
      |> insert()

    facility =
      :facility
      |> insert()

    :facility_location_group
    |> insert(
      location_group: location_group
    )

    {result, _} =
      facility
      |> FacilityContext.delete_facility_location_groups

    assert result == 0
  end

  test "validate_step2_changeset with valid params" do
    user =
      :user
      |> insert()

    facility =
      :facility
      |> insert()

    params = %{
      "updated_by_id" => user.id,
      "step" => 1,
      "line_1" => "some content",
      "line_2" => "some content",
      "region" => "some content",
      "city" => "some content",
      "province" => "some content",
      "country" => "some content",
      "postal_code" => "some content",
      "latitude" => "some content",
      "longitude" => "some content"
    }

    result =
      facility
      |> FacilityContext.validate_step2_changeset(params)

    assert {true, result}
  end

  test "validate_step2_changeset with invalid params" do
    user =
      :user
      |> insert()

    facility =
      :facility
      |> insert()

    params = %{
      "updated_by_id" => user.id,
      "step" => 1,
      "line_1" => "some content",
      "line_2" => "some content",
      "region" => "some content",
      "city" => "some content",
      "province" => "some content",
      "longitude" => "some content"
    }

    result =
      facility
      |> FacilityContext.validate_step2_changeset(params)

    assert {false, result}
  end

  test "delete_facility with valid id" do
    location_group =
      :location_group
      |> insert()

    contact =
      :contact
      |> insert()

    facility =
      :facility
      |> insert()

    _fc =
      :facility_contact
      |> insert(
        contact: contact,
        facility: facility
      )

    _flg =
      :facility_location_group
      |> insert(
        location_group: location_group,
        facility: facility
      )

    {cnt, _} =
      facility.id
      |> FacilityContext.delete_facility()

    assert cnt == 1
  end

  test "delete_facility with valid invalid id" do
    {cnt, _} =
      UUID.generate()
      |> FacilityContext.delete_facility()

    assert cnt == 0
  end

  test "get_facilities_by_location_group/1 got facility_ids" do
    location_group = insert(:location_group, name: "Northern")
    facility = insert(:facility)
    insert(:facility_location_group, facility: facility, location_group: location_group)
    facility_ids = FacilityContext.get_facilities_by_location_group("Northern")

    refute Enum.empty?(facility_ids)
  end

  test "get_facilities_by_location_group/1 got []" do
    insert(:location_group, name: "Northern")
    facility_ids = FacilityContext.get_facilities_by_location_group("Northern")

    assert Enum.empty?(facility_ids)
  end
end
