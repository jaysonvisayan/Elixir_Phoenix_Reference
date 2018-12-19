defmodule Innerpeace.Db.Base.PractitionerContextTest do
  use Innerpeace.Db.SchemaCase
  use Innerpeace.Db.PayorRepo, :context
  alias Innerpeace.Db.Schemas.{
    Practitioner,
    # PractitionerSpecialization,
    Contact,
    Phone,
    # Bank,
    AccountGroupAddress,
    PractitionerAccountContact,
    PractitionerSchedule
  }
  alias Innerpeace.Db.Repo

  alias Innerpeace.Db.Base.{
    PractitionerContext
  }

  alias Ecto.UUID

  @invalid_attrs %{}

  test "list all practitioners" do
    practitioners = insert(:practitioner, first_name: "test")
    assert get_all_practitioners() == [practitioners] |> Repo.preload([[practitioner_facilities: :facility], [practitioner_accounts: :account], [practitioner_specializations: :specialization], [practitioner_contact: [contact: [:phones, :emails]]]])
  end

  test "get_practitioner returns the practitioner with given id" do
    practitioner = :practitioner |> insert(first_name: "test") |> Repo. preload([:dropdown_vat_status,:practitioner_facilities])
    assert get_practitioner(practitioner.id) == practitioner |> Repo.preload([:logs, :bank, practitioner_accounts: :account, practitioner_specializations: :specialization, practitioner_contact: [contact: [:phones, :emails]]])
  end

  test "get practitioner using contact return practitioner with id" do
    practitioner = insert(:practitioner, first_name: "test")
    contact = insert(:contact)
    insert(:practitioner_contact, practitioner: practitioner, contact: contact)
    assert contact.id |> get_practitioner_using_contact() |> Repo.preload([:bank, practitioner_specializations: :specialization, practitioner_contact: [contact: [:phones, :emails]]])

  end

  test "create_practitioner with valid data creates a practitioner" do
    params = %{
      first_name: "test",
      last_name: "test",
      birth_date: Ecto.Date.utc(),
      effectivity_from: Ecto.Date.utc(),
      effectivity_to: Ecto.Date.utc(),
      gender: "test",
      affiliated: "yes",
      phic_accredited: "yes",
      prc_no: "123123123123",
      type: ["test"],
      specialization_ids: ["488412e1-1668-42b7-86d2-bd57f46678b6"]
    }
    assert {:ok, %Practitioner{} = practitioner} = create_practitioner(params)
    assert practitioner.first_name == "test"
  end

  test "create_practitioner with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = create_practitioner(@invalid_attrs)
  end

  test "update_practitioner with valid data updates the practitioner" do
    practitioner = insert(:practitioner)
    params = %{
      first_name: "test123",
      last_name: "test",
      birth_date: Ecto.Date.utc(),
      effectivity_from: Ecto.Date.utc(),
      effectivity_to: Ecto.Date.utc(),
      gender: "test",
      affiliated: "yes",
      phic_accredited: "Yes",
      prc_no: "123123123123",
      type: ["test"],
      specialization_ids: ["488412e1-1668-42b7-86d2-bd57f46678b6"]
    }
    assert {:ok, practitioner} = update_practitioner(practitioner.id, params)
    assert %Practitioner{} = practitioner
    assert practitioner.first_name == "test123"
  end

  test "update_practitioner with invalid data returns error changeset" do
    practitioner = :practitioner |> insert() |> Repo. preload([:dropdown_vat_status, :practitioner_facilities])
    assert {:error, %Ecto.Changeset{}} = update_practitioner(practitioner.id, @invalid_attrs)
    assert practitioner |> Repo.preload([:logs, :bank, practitioner_accounts: :account_group, practitioner_specializations: :specialization, practitioner_contact: [contact: [:phones, :emails]]]) == get_practitioner(practitioner.id)
  end

  test "delete_practitioner_contact deletes the practitioner_contact and contact" do
    practitioner = insert(:practitioner)
    contact = insert(:contact)
    insert(:practitioner_contact, practitioner: practitioner, contact: contact)
    delete_practitioner_contact(contact.id)
  end




  test "delete_practitioner deletes the practitioner" do
    practitioner = insert(:practitioner)
    assert {:ok, %Practitioner{}} = delete_practitioner(practitioner.id)
  end

  # test "set_practitioner_specializations adds practitioner specialization" do
  #   specialization = insert(:specialization, name: "Neurology")
  #   practitioner = insert(:practitioner, specialization_ids: [specialization.id], sub_specialization_ids: [])
  #   set_practitioner_specializations(practitioner.id, practitioner.specialization_ids, practitioner.sub_specialization_ids)
  #   practitioner = get_practitioner(practitioner.id)
  #   a = for ps <- practitioner.practitioner_specializations do
  #     ps.type
  #   end
  #   assert a == ["Primary"]
  # end

  test "delete_practitioner_specializations deletes practitioner specialization" do
    practitioner = insert(:practitioner)
    specialization = insert(:specialization)
    insert(:practitioner_specialization, practitioner: practitioner, specialization: specialization)
    practitioner = get_practitioner(practitioner.id)
    delete_practitioner_specializations(practitioner.id)
    deleted = get_practitioner(practitioner.id)
    assert Enum.empty?(deleted.practitioner_specializations)
  end

  test "update_step updates the step of the wizard" do
    practitioner = insert(:practitioner, step: 1)
    update_step(practitioner.id, %{step: 3})
    updated_practitioner = get_practitioner(practitioner.id)
    assert updated_practitioner.step == 3
  end

  test "get_practitioner_contacts gets the contacts of practitioner" do
    practitioner = insert(:practitioner)
    contact = insert(:contact)
    insert(:practitioner_contact, practitioner: practitioner, contact: contact)
    get_practitioner_contacts(practitioner.id)
    updated = get_practitioner(practitioner.id).practitioner_contact |> Ecto.assoc(:contact) |> Repo.all |> Repo.preload([:phones, :emails])
    assert get_practitioner_contacts(practitioner.id) == updated
  end

  test "create contact_practitioner with valid data" do
    insert(:practitioner)
    params = %{
      email: "admin@example.com"
    }
    assert {:ok, %Contact{} = contact} = create_contact_practitioner(params)
    assert contact.first_name == nil

  end

  test "update practitioner_contact with valid data" do
    practitioner = insert(:practitioner, first_name: "test")
    contact = insert(:contact)
    insert(:practitioner_contact, practitioner: practitioner, contact: contact)
    params = %{
      email: "admin@example.com"
    }
    {:ok, %Contact{} = contact} = update_contact_practitioner(contact, params)
    assert contact.first_name == nil

  end

  test "create practitioner_contact with valid data" do
    practitioner = insert(:practitioner, first_name: "test")
    contact = insert(:contact)
    params = %{
      contact_id: contact.id,
      practitioner_id: practitioner.id
    }
    practitioner_contact = create_practitioner_contact(params)
    assert practitioner_contact.practitioner_id == practitioner.id
    assert practitioner_contact.contact_id == contact.id
  end

  test "create number for contact with valid data" do
    contact = insert(:contact)
    params = %{
      contact_id: contact.id,
      number: "123456788",
      type: "telephone"
    }
    assert {:ok, %Phone{}} = create_no(params)
  end

  test "create_practitioner_financial with valid data creates practitioner_financial" do
    vatable = insert(:dropdown, type: "VAT Status", text: "Vatable")
    practitioner = insert(:practitioner)
    params = %{
      "exclusive" => ["PCs"],
      "vat_status" => "20% VAT-able",
      "prescription_period" => "12312312",
      "tin" => "123456789012",
      "withholding_tax" => "12345667777",
      "vat_status_id" => vatable.id
    }
    assert {:ok, %Practitioner{} = practitioner} = create_practitioner_financial(practitioner.id, params)
    assert practitioner.tin == "123456789012"
  end

  test "create practitioner_financial with invalid data returns error changeset" do
    practitioner = insert(:practitioner)
    assert {:error, %Ecto.Changeset{}} = create_practitioner_financial(practitioner.id,@invalid_attrs)
  end

  test "get_practitioner_accounts lists all practitioner accounts" do
    practitioner = insert(:practitioner)
    account = insert(:account_group, code: "test123")
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    practitioner = get_practitioner(practitioner.id)
    result =
      practitioner.id
      |> get_practitioner_accounts() |> Repo.preload(:practitioner)
    assert result ==
      [pa]
      |> Repo.preload([
        :practitioner_schedules,
        [account_group:
         [
           [account_group_contacts: [contact: [:phones]]],
           [account_group_address: from(aga in AccountGroupAddress, order_by: aga.type)]
         ],
        ],
        [practitioner_account_contact:
         [contact:
          [:phones]
         ]
        ]
      ])
  end

  test "get_practitioner_account shows a practitioner account" do
    practitioner = insert(:practitioner)
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    result =
      pa.id
      |> get_practitioner_account() |> Repo.preload(:practitioner)
    assert result == pa |> Repo.preload(:practitioner_account_contact)
  end

  test "create_practitioner_facility with valid params" do
    facility = insert(:facility)
    practitioner = insert(:practitioner)
    user = insert(:user)
    status = insert(:dropdown)

    params = %{
      "affiliation_date" => "2017-12-12",
      "disaffiliation_date" => "2017-12-12",
      "payment_mode" => "umbrella",
      "credit_term" => 1,
      "step" => 1,
      "created_by_id" => user.id,
      "updated_by_id" => user.id,
      "facility_id" => facility.id,
      "practitioner_id" => practitioner.id,
      "pstatus_id" => status.id
    }

    {status, struct} =  create_practitioner_facility(params, user.id, practitioner)
    assert status == :ok
    assert struct.payment_mode == "umbrella"
  end

  test "create_practitioner_facility with invalid params" do
    practitioner = insert(:practitioner)
    user = insert(:user)
    params = %{}

    {status, _struct} =  create_practitioner_facility(params, user.id, practitioner)

    assert status == :error
  end

  test "update_practitioner_facility_step1 with valid params" do
    facility = insert(:facility)
    practitioner = insert(:practitioner)
    user = insert(:user)
    status = insert(:dropdown)
    practitioner_facility = insert(:practitioner_facility)

    params = %{
      "affiliation_date" => "2017-12-12",
      "disaffiliation_date" => "2017-12-12",
      "payment_mode" => "umbrella",
      "credit_term" => 1,
      "step" => 1,
      "created_by_id" => user.id,
      "updated_by_id" => user.id,
      "facility_id" => facility.id,
      "practitioner_id" => practitioner.id,
      "pstatus_id" => status.id,
      "fixed" => true
    }

    {status, struct} =  update_practitioner_facility_step1(user.id, params, practitioner_facility, practitioner)
    assert status == :ok
    assert struct.payment_mode == "umbrella"
  end

  test "update_practitioner_facility_step1 with invalid params" do
    practitioner_facility = insert(:practitioner_facility)
    practitioner = insert(:practitioner)
    user = insert(:user)

    params = %{}

    {status, _struct} =  update_practitioner_facility_step1(user.id, params, practitioner_facility, practitioner)

    assert status == :error
  end

  test "update_practitioner_facility_step3 with valid params" do
    insert(:facility)
    practitioner = insert(:practitioner)
    user = insert(:user)
    cp_clearance = insert(:dropdown)
    practitioner_facility = insert(:practitioner_facility)

    params = %{
      "step" => 1,
      "updated_by_id" => user.id,
      "coordinator" => true,
      "consultation_fee" => 1.00,
      "cp_clearance_rate" => 1.00,
      "cp_clearance_id" => cp_clearance.id
    }

    {status, struct} =  update_practitioner_facility_step3(params, practitioner_facility, user.id, practitioner,false)
    assert status == :ok
    assert struct.coordinator == true
  end

  test "update_practitioner_facility_step3 with invalid params" do
    practitioner_facility = insert(:practitioner_facility)
    practitioner = insert(:practitioner)
    user = insert(:user)

    params = %{}

    {status, _struct} =  update_practitioner_facility_step3(params, practitioner_facility, user.id, practitioner, false)
    assert status == :error
  end

  test "get_practitioner_facilities with valid practitioner id" do
    facility = insert(:facility)
    practitioner = insert(:practitioner)
    insert(:practitioner_facility,
           facility: facility,
           practitioner: practitioner)

    result = get_practitioner_facilities(practitioner.id)

    assert Enum.count(result) == 1
  end

  test "get_practitioner_facilities with invalid practitioner id" do
    id = UUID.generate()

    result = get_practitioner_facilities(id)

    assert result == []
  end

  test "get_practitioner_facility with valid id" do
    facility = insert(:facility)
    practitioner = insert(:practitioner)
    practitioner_facility = insert(:practitioner_facility,
                                   facility: facility,
                                   practitioner: practitioner
    )

    result = get_practitioner_facility(practitioner_facility.id)

    assert result.id == practitioner_facility.id
  end

  test "get_practitioner_facility with invalid id" do
    id = UUID.generate()

    result = get_practitioner_facility(id)

    assert result == nil
  end

  test "create_practitioner_facility_type with valid params" do
    practitioner_facility = insert(:practitioner_facility)
    params = %{
      type: "test",
      practitioner_facility_id: practitioner_facility.id
    }

    {status, struct} = create_practitioner_facility_type(params)

    assert status == :ok
    assert struct.type == "test"
  end

  test "create_practitioner_facility_type with invalid params" do
    params = %{
      type: "test",
    }

    {status, _struct} = create_practitioner_facility_type(params)

    assert status == :error
  end

  test "delete_practitioner_facility_type with valid id" do
    facility = insert(:facility)
    practitioner = insert(:practitioner)
    pf = insert(:practitioner_facility, facility: facility, practitioner: practitioner)
    pfpt = insert(:practitioner_facility_practitioner_type, practitioner_facility: pf)

    {_status, result} = PractitionerContext.delete_practitioner_facility_type(pfpt.id)

    assert is_nil(result)
  end

  test "get_practitioner_account_contact gets contact from practitioner_account" do
    practitioner = insert(:practitioner)
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    contact = insert(:contact)
    pa_contact = insert(:practitioner_account_contact, practitioner_account: pa, contact: contact)
    _result = get_practitioner_account_contact(pa_contact.id)
    assert _result = pa_contact
  end

  test "create_practitioner_account_contact adds a contact within a practitioner account with valid attributes" do
    practitioner = insert(:practitioner)
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    contact = insert(:contact)

    params = %{
      practitioner_account_id: pa.id,
      contact_id: contact.id
    }

    assert {:ok, %PractitionerAccountContact{}} = create_practitioner_account_contact(params)
  end

  test "create_practitioner_account_contact does not add a contact within a practitioner account with invalid attributes" do
    practitioner = insert(:practitioner)
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    insert(:contact)

    params = %{
      practitioner_account_id: pa.id,
      contact_id: ""
    }

    assert {:error, %Ecto.Changeset{}} = create_practitioner_account_contact(params)
  end

  test "delete_practitioner_account_contact deletes practitioner_account_contact" do
    practitioner = insert(:practitioner)
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    contact = insert(:contact)
    pac = insert(:practitioner_account_contact, practitioner_account: pa, contact: contact)
    contact = get_practitioner_account_contact(pac.id)
    delete_practitioner_account_contact(contact.contact_id)
    pa = get_practitioner_account(pa.id)

    deleted_contact =
      pa.id
      |> get_practitioner_account()
      |> Repo.preload(:practitioner_account_contact)
    assert is_nil(deleted_contact.practitioner_account_contact)
  end

  test "get_practitioner_account_schedules lists all schedules within a practitioner account" do
    practitioner = insert(:practitioner)
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    schedule = insert(:practitioner_schedule, practitioner_account: pa)
    pa = get_practitioner_account(pa.id)
    _result = get_practitioner_account_schedules(pa.id)
    assert _result = [schedule]
  end

  test "create_practitioner_account_schedule adds a schedule for a practitioner account" do
    practitioner = insert(:practitioner)
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    params = %{
      day: "Monday",
      room: "23",
      time_from: Ecto.Time.utc(),
      time_to: Ecto.Time.utc(),
      practitioner_account_id: pa.id
    }
    assert {:ok, %PractitionerSchedule{}} = create_practitioner_account_schedule(params)
  end

  test "create_practitioner_account_schedule with invalid params does not add  a schedule for a practitioner account" do
    practitioner = insert(:practitioner)
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    params = %{
      day: "Monday",
      room: "23",
      time_from: "asdasd",
      time_to: Ecto.Time.utc(),
      practitioner_account_id: pa.id
    }
    assert {:error, %Ecto.Changeset{}} = create_practitioner_account_schedule(params)
  end

  test "delete_practitioner_account_schedule deletes practitioner account schedule" do
    practitioner = insert(:practitioner)
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    schedule = insert(:practitioner_schedule, practitioner_account: pa)

    delete_practitioner_account_schedule(schedule.id)

    deleted_schedule =
      pa.id
      |> get_practitioner_account()
      |> Repo.preload(:practitioner_schedules)

    assert Enum.empty?(deleted_schedule.practitioner_schedules)
  end

  test "delete_practitioner_account deletes practitioner account" do
    practitioner = insert(:practitioner)
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)

    delete_practitioner_account(pa.id)
    deleted_practitioner_account =
      practitioner.id
      |> get_practitioner()
      |> Repo.preload(:practitioner_accounts)
    assert Enum.empty?(deleted_practitioner_account.practitioner_accounts)
  end

  test "expired_practitioner changes status to disaffiliated if practitioner effectivity date is expired" do
    practitioner = insert(:practitioner, effectivity_from: Ecto.Date.utc(), effectivity_to: Ecto.Date.utc(), status: "Affiliated")
    expired_practitioner(practitioner.id)
    updated_practitioner = get_practitioner(practitioner.id)

    assert updated_practitioner.status == "Disaffiliated"
  end

  test "practitioner_csv_downloads downloads csv result from practitioner search page" do
    insert(:practitioner, code: "PRA_123456")
    params = %{"practitioner_code" => ["PRA_123456"]}
    query = for code <- params["practitioner_code"] do
      practitioner =
        Practitioner
        |> Repo.get_by!(code: code)
        |> Repo.preload([
          :logs,
          :bank,
          practitioner_accounts: :account_group,
          practitioner_specializations: :specialization,
          practitioner_facilities: :facility,
          practitioner_contact: [contact: [:phones, :emails]]
        ])
      specialization = for practitioner_specialization <- Enum.reject(practitioner.practitioner_specializations, &(&1.type == "Secondary")) do
        "#{practitioner_specialization.specialization.name}"
      end
      sub_specialization = for practitioner_specialization <- Enum.reject(practitioner.practitioner_specializations, &(&1.type == "Primary")) do
        "#{practitioner_specialization.specialization.name}"
      end
      facility_name = for practitioner_facility <- practitioner.practitioner_facilities do
        "#{practitioner_facility.facility.name}"
      end
      facility_code = for practitioner_facility <- practitioner.practitioner_facilities do
        "#{practitioner_facility.facility.code}"
      end
      [practitioner.code, "#{practitioner.first_name} #{practitioner.middle_name} #{practitioner.last_name}", practitioner.status, Enum.join(specialization, ", "), Enum.join(sub_specialization, ", "), Enum.join(facility_code, ", "), Enum.join(facility_name, ", ")]
    end
    assert query == PractitionerContext.practitioner_csv_downloads(params)
  end

  #Start of MemberLink Test
  test "search practitioner return practitioner facility and specialization" do
    member = insert(:member, first_name: "Shane")
    account = insert(:account)
    product = insert(:product)
    coverage = insert(:coverage)
    product_coverage = insert(:product_coverage, product: product, coverage: coverage)
    practitioner = insert(:practitioner, first_name: "jayson", middle_name: "binayug", last_name: "visayan", gender: "Female", status: "Affiliated")
    dropdown = insert(:dropdown, type: "Facility Type", text: "HOSPITAL-BASED", value: "HB")
    facility = insert(:facility, name: "General Hospital", step: 7, status: "Affiliated", type: dropdown)
    insert(:product_coverage_facility, product_coverage: product_coverage, facility: facility)
    specialization = insert(:specialization, name: "Neurology")
    prac_fac = insert(:practitioner_facility, practitioner_id: practitioner.id, facility_id: facility.id)
    insert(:practitioner_schedule, practitioner_facility: prac_fac, day: "tuesday")
    insert(:practitioner_specialization, practitioner_id: practitioner.id, specialization_id: specialization.id, type: "Primary")
    account_product = insert(:account_product, account: account, product: product)
    member_product = insert(:member_product, member: member, account_product: account_product)
    user = insert(:user, first_name: "Shane", member: member_product.member)
    params = %{"name" => "jayson"}
    search_practitioner = PractitionerContext.search_practitioner_api(params, user.member_id)
    assert Enum.at(search_practitioner, 0).practitioner.first_name == practitioner.first_name
  end
  #End of MemberLink Test

  test "update_pf_fee/1, Updated fee of a practitioner based in his/her specialization with valid parameters" do
    specialization = insert(:specialization, name: "Neurology")
    practitioner = insert(:practitioner, specialization_ids: [specialization.id], sub_specialization_ids: [])
    facility = insert(:facility, name: "General Hospital")
    pf = insert(:practitioner_facility, practitioner_id: practitioner.id, facility_id: facility.id)
    set_practitioner_specializations(practitioner.id, practitioner.specialization_ids, practitioner.sub_specialization_ids)

    p_record =
      Practitioner
      |> where([p], p.id == ^practitioner.id)
      |> Repo.one
      |> Repo.preload([:practitioner_specializations])

    cfs = for ps <- p_record.practitioner_specializations, do: %{"cf_#{ps.id}" => "0.00"}

    result = for {result, _r} <- update_pf_fee(cfs, pf.id) do
      result
    end
    |> Enum.uniq
    |> List.delete(:ok)

    assert Enum.empty?(result)
  end

  # test "update_pf_fee/1, Updated fee of a practitioner based in his/her specialization with invalid parameters" do
  #   specialization = insert(:specialization, name: "Neurology")
  #   practitioner = insert(:practitioner, specialization_ids: [specialization.id], sub_specialization_ids: [])
  #   facility = insert(:facility, name: "General Hospital")
  #   pf = insert(:practitioner_facility, practitioner_id: practitioner.id, facility_id: facility.id)
  #   set_practitioner_specializations(practitioner.id, practitioner.specialization_ids, practitioner.sub_specialization_ids)

  #   p_record =
  #     Practitioner
  #     |> where([p], p.id == ^practitioner.id)
  #     |> Repo.one
  #     |> Repo.preload([:practitioner_specializations])

  #   cfs = for ps <- p_record.practitioner_specializations, do: %{"cf_#{ps.id}" => "not valid 123.,."}

  #   result = for {result, r} <- update_pf_fee(cfs, pf.id) do
  #     result
  #   end
  #   |> Enum.uniq
  #   |> List.delete(:ok)

  #   refute Enum.empty?(result)
  # end

end

