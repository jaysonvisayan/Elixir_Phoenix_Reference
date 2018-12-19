defmodule Innerpeace.Db.Base.MemberContextTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.{
    Member,
    MemberProduct,
    MemberComment,
    Peme
    # MemberContact
  }
  alias Innerpeace.Db.Base.MemberContext
  alias Ecto.UUID

  test "get_member!/1 returns the member with given id" do
    member =
      :member
      |> insert()
      |> Repo.preload([
        :dependents,
        :principal,
        :kyc_bank,
        :member_logs,
        :created_by,
        :updated_by,
        :prinicipal_member_product,
        products: :product,
        member_comments: {from(mc in MemberComment, order_by: [desc: mc.inserted_at]), [:updated_by, :created_by]},
        account_group: [:account, :payment_account],
        authorizations: [
         :facility,
         :special_approval,
         :room,
         :created_by,
         :authorization_amounts,
         :authorization_diagnosis,
         authorization_practitioners: :practitioner,
         authorization_diagnosis: [:diagnosis, :product_benefit],
         coverage: [coverage_benefits: :benefit],
         authorization_procedure_diagnoses: [product_benefit: :benefit]
        ]
      ])

    assert MemberContext.get_member!(member.id) == member
  end

  test "get_member!/1 with no members found" do
    member =
      :member
      |> insert()
      |> Repo.preload([
        :dependents,
        :principal,
        :kyc_bank,
        :member_logs,
        :created_by,
        :updated_by,
        :prinicipal_member_product,
        products: :product,
        member_comments: {from(mc in MemberComment, order_by: [desc: mc.inserted_at]), [:updated_by, :created_by]},
        account_group: [:account, :payment_account],
        authorizations: [
         :facility,
         :special_approval,
         :room,
         :created_by,
         :authorization_amounts,
         :authorization_diagnosis,
         authorization_practitioners: :practitioner,
         authorization_diagnosis: [:diagnosis, :product_benefit],
         coverage: [coverage_benefits: :benefit],
         authorization_procedure_diagnoses: [product_benefit: :benefit]
        ]
      ])

    assert MemberContext.get_member!("6f84ae80-0f2a-41b8-a312-4580601b54f8") == nil
  end

  test "get_loa_by_product/2" do
    p_1 = insert(:product, name: "1")
    #p_2 = insert(:product, name: "2")
    m = insert(:member)
    a = insert(:account)
    ap_1 = insert(:account_product, account: a, product: p_1)
    #ap_2 = insert(:account_product, account: a, product: p_2)
    mp = insert(:member_product, member: m, account_product: ap_1)
    a = insert(:authorization, member: m, number: "1")
    a_2 = insert(:authorization, member: m, number: "2")
    _ad = insert(:authorization_diagnosis, authorization: a, member_product: mp)
    _apd = insert(:authorization_procedure_diagnosis, authorization: a_2, member_product: mp)
    _abp = insert(:authorization_benefit_package, authorization: a_2, member_product: mp)

    refute Enum.empty?(MemberContext.get_loa_by_product(m.id, p_1.id))
  end

  test "get_all_members/0 returns all members" do
    member =
      :member
      |> insert()
      |> Repo.preload([
        :account_group,
        skipped_dependents: :created_by,
        products: :product,
      ])
    assert MemberContext.get_all_members() == [member]
  end

  test "get_principal_members/0 returns all principal members" do
    member =
      :member
      |> insert(%{type: "Principal"})
      |> Repo.preload([
        :account_group,
        products: :product,
      ])
    assert MemberContext.get_principal_members() == [member]
  end

  test "create_member/1 creates member with valid attributes" do
    account_group = insert(:account_group, code: "code101")
    member_params = %{
      account_code: account_group.code,
      type: "Principal",
      effectivity_date: "2017-08-15",
      expiry_date: "2017-08-20",
      first_name: "test",
      middle_name: "test",
      last_name: "test",
      gender: "Male",
      civil_status: "Single",
      birthdate: "1995-12-18",
      employee_no: "123",
      date_hired: "2012-12-12",
      is_regular: false,
      regularization_date: "2017-01-01",
      tin: "test",
      philhealth: "test",
      for_card_issuance: true
    }
    assert {:ok, %Member{} = member} = MemberContext.create_member(member_params)
    assert member.first_name == "test"
  end

  test "update_member_step/2 updates members current step" do
    member = insert(:member, %{first_name: "test123"})
    assert {:ok, %Member{}} = MemberContext.update_member_step(member, %{step: "2", updated_by_id: UUID.generate()})
  end

  test "create_member/1 does not create member with invalid attributes" do
    member_params = %{}
    assert {:error, %Ecto.Changeset{} = changeset} = MemberContext.create_member(member_params)
    refute Enum.empty?(changeset.errors)
  end

  test "update_member_general/2 updates members general information with valid attributes" do
    member = insert(:member, %{first_name: "test123"})
    account_group = insert(:account_group, code: "code101")
    member_params = %{
      account_code: account_group.code,
      type: "Principal",
      effectivity_date: "2017-08-15",
      expiry_date: "2017-08-20",
      first_name: "updated first name",
      middle_name: "test",
      last_name: "test",
      gender: "Male",
      civil_status: "Single",
      birthdate: "1995-12-18",
      employee_no: "123",
      date_hired: "2012-12-12",
      is_regular: false,
      regularization_date: "2017-01-01",
      tin: "test",
      philhealth: "test",
      for_card_issuance: true
    }
    assert {:ok, %Member{} = member} = MemberContext.update_member_general(member, member_params)
    assert member.first_name == "updated first name"
  end

  test "update_member_general/2 does not update members general information with invalid attributes" do
    member = insert(:member, %{first_name: "test123"})
    member_params = %{}
    assert {:error, %Ecto.Changeset{} = changeset} = MemberContext.update_member_general(member, member_params)
    refute Enum.empty?(changeset.errors)
  end

  test "update_member_contact/2 updates members contact information with valid attributes" do
    member = insert(:member)
    member_params = %{
      email: "test@gmail.com",
      mobile: "123123123"
    }
    assert {:ok, %Member{} = member} = MemberContext.update_member_contact(member, member_params)
    assert member.email == "test@gmail.com"
  end

  test "update_member_contact/2 does not update members contact information with invalid attributes" do
    member = insert(:member)
    member_params = %{}
    assert _changeset = MemberContext.update_member_contact(member, member_params)
  end

  test "set_member_products/2 sets products of given member" do
    member = insert(:member, card_no: "12312312") |> Repo.preload(:products)
    account_product = insert(:account_product)
    MemberContext.set_member_products(member, [account_product.id])
    member = MemberContext.get_member!(member.id)
    refute Enum.empty?(member.products)
  end

  test "clear_member_products/1 removes all products associated to the given member" do
    member = insert(:member) |> Repo.preload(:products)
    account_product = insert(:account_product)
    MemberContext.set_member_products(member, [account_product.id])
    member = MemberContext.get_member!(member.id)
    refute Enum.empty?(member.products)
    MemberContext.clear_member_products(member.id)
    member = MemberContext.get_member!(member.id)
    assert Enum.empty?(member.products)
  end

  test "deleting_member_product/2, remove selected product in show page" do
    member_product = insert(:member_product, tier: 1)
    MemberContext.delete_member_account_product(member_product.member_id, member_product.id)
    mp = Repo.get(MemberProduct, member_product.id)
    assert mp == nil
  end

  #MemberLink Test

  test "update_member_profile updates profile of member and returns member params are valid" do
    member = insert(:member)
    params = %{
      first_name: "Jayson",
      last_name: "Visayan",
      gender: "Male",
      birth_date: "09/30/1990"
    }
    assert {:ok, %Member{}} = MemberContext.update_member_profile(member, params)
  end

  test "update_member_profile updates profile of member and returns changeset when params are invalid" do
    member = insert(:member)
    params = %{
      gender: "Male",
      birth_date: "09/30/1990"
    }
    assert {:error, _changeset} = MemberContext.update_member_profile(member, params)
  end

  test "get_dependents_by_member_id returns dependents of member" do
    member = insert(:member)
    insert(:member, principal_id: member.id)
    assert [%Member{}] = MemberContext.get_dependents_by_member_id(member.id)
  end

  test "get_dependents_by_member_id returns nothin when there's no dependents within members" do
    member = insert(:member)
    insert(:member, principal_id: member.id)
    assert [%Member{}] = MemberContext.get_dependents_by_member_id(member.id)
  end

  test "create_dependent creates dependent and returns dependent when params are valid" do
    params = %{
      "salutation" => "Sir",
      "first_name" => "Joeffrey",
      "last_name" => "Baratheon",
      "gender" => "Male",
      "extension" => "Jr.",
      "relationship" => "Bad Influence friend",
      "birthdate" => "1990-08-04T00:00:00Z"
    }
    assert {:ok, _member} = MemberContext.create_dependent(params)
  end

  test "create_dependent creates dependent and returns error when params are invalid" do
    params = %{
      "salutation" => "Sir",
      "first_name" => "Joeffrey",
      "last_name" => "Baratheon",
      "gender" => "Male",
      "extension" => "Jr.",
      "birthdate" => "1990-08-04T00:00:00Z"
    }
    assert {:error, _changeset} = MemberContext.create_dependent(params)
  end

  test "get_emergency_contact gets emergency_contact" do
    member = insert(:member)
    contact = insert(:contact)
    member_contact = insert(:member_contact, member_id: member.id, contact_id: contact.id)
    assert member_contact == MemberContext.get_emergency_contact(member.id)
  end

  test "validate_member_info validates members_info when params are valid" do
    member = insert(:member)
    params = %{
      "blood_type" => "string",
      "allergies" => "string",
      "medication" => "string"
    }
    assert {:ok, "info"} == MemberContext.validate_member_info(member, params)
  end

  test "validate_emergency_contact validates emergency_contact when params are valid" do
    params = %{
    "first_name" => "string",
    "middle_name" => "string",
    "last_name" => "string",
    "relationship" => "string",
    }
    assert {:ok, "contact"} == MemberContext.validate_emergency_contact(params)
  end

  test "validate_emergency_hospital validates emergency_hospital when params are valid" do
    member = insert(:member)
    params = %{
      "member_id" => member.id,
      "name" => "string",
      "phone" => "12345678900",
      "hmo" => "string",
      "card_number" => 0,
      "policy_number" => 0,
      "customer_care_number" => 0
    }
    assert {:ok, "hospital"} == MemberContext.validate_hospital(params)
  end

  test "insert_member_info inserts members_info when params are valid" do
    member = insert(:member)
    params = %{
      "blood_type" => "string",
      "allergies" => "string",
      "medication" => "string"
    }
    assert {:ok, _member} = MemberContext.insert_member_info(member, params)
  end

  test "create_emergency_contact inserts emergency_contact when params are valid" do
    params = %{
    "first_name" => "string",
    "middle_name" => "string",
    "last_name" => "string",
    "relationship" => "string",
    "phones" => [1_233_123],
    "emails" => ["john@baho.com"]
    }
    assert {:ok, _contact} = MemberContext.create_emergency_contact(params)
  end

  test "insert_member_emergency_contact inserts member_emergency_contact when params are valid" do
    member = insert(:member)
    contact = insert(:contact)
    assert {:ok, _contact} = MemberContext.insert_member_emergency_contact(member.id, contact.id)
  end

  test "insert_emergency_hospital inserts emergency_hospital when params are valid" do
    member = insert(:member)
    params = %{
      "member_id" => member.id,
      "name" => "string",
      "phone" => "12345678909",
      "hmo" => "string",
      "card_number" => 0,
      "policy_number" => 0,
      "customer_care_number" => 0
    }
    assert {:ok, _hospital} = MemberContext.insert_member_emergency_hospital(params)
  end

  test "update_emergency_contact updates emergency_contact when params are valid" do
    member = insert(:member)
    params = %{
    "first_name" => "string",
    "middle_name" => "string",
    "last_name" => "string",
    "relationship" => "string",
      "phones" => [],
    "emails" => []
    }
    assert {:ok, _contact} = MemberContext.update_emergency_contact(member.id, params)
  end

  test "update_member_emergency_contact updates member_emergency_contact when params are valid" do
    member = insert(:member)
    contact = insert(:contact)
    assert {:ok, _contact} = MemberContext.insert_member_emergency_contact(member.id, contact.id)
  end

  test "insert_emergency_hospital inserts emergiency_hospital when params are valid" do
    member = insert(:member)
    params = %{
      "member_id" => member.id,
      "name" => "string",
      "phone" => "12345678909",
      "hmo" => "string",
      "card_number" => 0,
      "policy_number" => 0,
      "customer_care_number" => 0
    }
    assert {:ok, _hospital} = MemberContext.update_member_emergency_hospital(member.id, params)
  end

  #MemberLink Test

  test "active_account with valid date" do
    member = insert(:member, status: "Pending", effectivity_date: "2017-08-08")
    member =  MemberContext.active_member(member)

    assert member.status == "Active"

  end

  test "active_account with invalid date" do
    member = insert(:member, status: "Pending", effectivity_date: "2050-08-08")
    member =  MemberContext.active_member(member)

    assert is_nil(member) == true

  end

  test "reactivation_account with valid date" do
    member = insert(:member, status: "Suspended", reactivate_date: "2017-08-19")
    member = MemberContext.reactivation_member(member)

    assert member.status == "Active"
  end

  test "reactivation_account with invalid date" do
    member = insert(:member, status: "Suspended", reactivate_date: "2050-08-19")
    member = MemberContext.reactivation_member(member)

    assert is_nil(member) == true
  end

  test "suspension_account with valid date" do
    member = insert(:member, status: "Active", suspend_date: "2017-08-19")
    member = MemberContext.suspension_member(member)

    assert member.status == "Suspended"
  end

  test "suspension_account with invalid date" do
    member = insert(:member, status: "Active", suspend_date: "2050-08-19")
    member = MemberContext.suspension_member(member)

    assert is_nil(member) == true
  end

  test "cancellation_account with valid date" do
    member = insert(:member, status: "Active", cancel_date: "2017-08-19")
    member = MemberContext.cancellation_member(member)

    assert member.status == "Cancelled"
  end

  test "cancellation_account with invalid date" do
    member = insert(:member, status: "Active", cancel_date: "2050-08-19")
    member = MemberContext.cancellation_member(member)

    assert is_nil(member) == true
  end

  test "expired_member with expired date" do
    member = insert(:member, status: "Active", expiry_date: "2017-08-01")
    member = MemberContext.expired_member(member)

    assert member.status == "Lapsed"
  end

  test "expired_member with not expired date" do
    member = insert(:member, status: "Active", expiry_date: "2050-01-01")
    member = MemberContext.expired_member(member)

    assert is_nil(member) == true
  end

  #AccountLink Function
  test "get_all_member_based_on_account" do
    account_group = insert(:account_group, code: "1234")
    member = insert(:member, account_code: account_group.code, card_no: "1231231232")
    all_member = MemberContext.get_all_member_based_on_account(account_group.code)
    assert member.id == Enum.at(all_member, 0).id
  end

  test "single_peme_create/1, inserts a new peme record with valid params" do
    params = %{
      first_name: "Edward",
      middle_name: "E",
      last_name: "Elric",
      birthdate: Ecto.Date.cast!("1999-11-26"),
      civil_status: "Married",
      gender: "Male",
      effectivity_date: Ecto.Date.cast!("1999-11-12"),
      expiry_date: Ecto.Date.cast!("1999-11-11"),
      step: 2
    }

    {:ok, peme_record} = MemberContext.single_peme_create(params)
    assert peme_record.first_name == "Edward"
    assert peme_record.last_name == "Elric"
    assert peme_record.birthdate == Ecto.Date.cast!("1999-11-26")
  end

  test "single_peme_create/1, inserts a new peme record with invalid params" do
    params = %{
      first_name: nil,
      last_name: nil,
      birthdate: nil,
      civil_status: nil,
      gender: nil,
      effectivity_date: nil,
      expiry_date: nil,
      step: nil
    }

    assert {:error, %Ecto.Changeset{} = changeset} = MemberContext.single_peme_create(params)
    refute Enum.empty?(changeset.errors)
  end

  test "single_peme_update_general/2, updates a peme record according to general fields with valid params" do
    member = insert(:member)
    params = %{
      first_name: "Edward",
      middle_name: "C",
      last_name: "Elric",
      birthdate: Ecto.Date.cast!("1999-11-26"),
      civil_status: "Married",
      gender: "Male",
      effectivity_date: Ecto.Date.cast!("1999-11-12"),
      expiry_date: Ecto.Date.cast!("1999-11-11"),
      step: 2
    }

    assert {:ok, _member} = MemberContext.single_peme_update_general(member.id, params)
  end

  test "single_peme_update_general/2, updates a peme record according to general fields with invalid params" do
    member = insert(:member)
    params = %{
      first_name: 123,
      last_name: 123
    }

    assert {:error, _changeset} = MemberContext.single_peme_update_general(member.id, params)
  end

  test "single_peme_update_contact/2, updates a peme record according to contact fields with valid params" do
    member = insert(:member)
    params = %{
      email: "a@b.c",
      mobile: "09123459789",
      step: "4"
    }

    assert {:ok, _peme_record} = MemberContext.single_peme_update_contact(member.id, params)
  end

  test "single_peme_update_contact/2, updates a peme record according to contact fields with invalid params" do
    member = insert(:member)
    params = %{
      email: nil,
      mobile: "09123459789",
      step: "4"
    }

    assert {:error, _changeset} = MemberContext.single_peme_update_contact(member.id, params)
  end

  # test "single_peme_request_loa/1, inserts a new PEME Loa record with valid params" do
  #   member = insert(:member)
  #   package = insert(:package)

  #   params = %{
  #     member_id: member.id,
  #     package_id: package.id,
  #     peme_date: Ecto.Date.cast!("1999-11-11")
  #   }

  #   assert {:ok, _peme_loa} = MemberContext.single_peme_request_loa(params)
  # end

  # test "single_peme_request_loa/1, inserts a new PEME Loa record with invalid params" do
  #   member = insert(:member)
  #   package = insert(:package)

  #   params = %{
  #     member_id: member.id,
  #     package_id: package.id,
  #   }

  #   assert {:error, _changeset} = MemberContext.single_peme_request_loa(params)
  # end
  #End AccountLink Function

  test "get_active_member_by_card_no with valid params" do
    ag = insert(:account_group)
    insert(:account, account_group: ag, status: "Active")
    insert(:member, card_no: "1123456123123123", account_group: ag, status: "Active")
    result = MemberContext.get_active_member_by_card_no("1123456123123123")

    assert result.card_no == "1123456123123123"
  end

  test "get_active_member_by_card_no with invalid params" do
    ag = insert(:account_group)
    insert(:account, account_group: ag, status: "Active")
    insert(:member, card_no: "1123456123123123", account_group: ag, status: "Active")
    result = MemberContext.get_active_member_by_card_no("112345612312313")

    assert is_nil(result)
  end

  test "enroll_member with valid params" do
    member =
      insert(:member)

    params = %{
      step: "5",
      updated_by_id: UUID.generate,
      enrollment_date: "2018-01-01",
      card_expiry_date: "2022-01-01"
    }

    {status, result} =
      member
      |> MemberContext.enroll_member(params)

    assert status == :ok
    assert result.enrollment_date == Ecto.Date.cast!("2018-01-01")
  end

  test "enroll_member with invalid params" do
    member =
      insert(:member)

    params = %{
      step: "5",
      updated_by_id: UUID.generate,
      card_expiry_date: "2022-01-01"
    }

    {status, result} =
      member
      |> MemberContext.enroll_member(params)

    assert status == :error
    refute result.valid?
  end

  test "get_member_by_card_no with valid params" do
    member =
      insert(:member, card_no: "6050831100000025")

    result =
      "6050831100000025"
      |> MemberContext.get_member_by_card_no()

    assert result.id == member.id
  end

  test "get_member_by_card_no with invalid params" do
    insert(:member, card_no: "6050831100000025")

    result =
      "605083110000005"
      |> MemberContext.get_member_by_card_no()

    assert is_nil(result)
  end

  test "create_member_logs insert logs for member creation" do
    user = insert(:user)
    member = insert(:member, first_name: "sample", last_name: "sample")
    member_log = MemberContext.create_member_log(user, member)
    assert member.id == member_log.member_id
  end

  test "movement_member_logs insert logs for member movement" do
    user = insert(:user)
    member = insert(:member, first_name: "sample", last_name: "sample")
    params = %{
      suspension_date: "3000-01-01",
      suspension_reason: "Reason 1",
      suspension_remarks: "Remarks"
    }
    member_log =  MemberContext.movement_member_log(user, member, params, "suspend")
    assert member.id == member_log.member_id
  end

  test "get_member_logs returns member logs" do
    user = insert(:user)
    member = insert(:member, first_name: "sample", last_name: "sample")
    inserted_member_log = MemberContext.create_member_log(user, member)
    member_logs = MemberContext.get_member_logs(member.id)
    assert member_logs == [inserted_member_log]
  end

  test "valid_evoucher_reprint?/2 returns struct when params are valid" do
    account_group = insert(:account_group, name: "TEST-ACCOUNT")
    member = insert(:member, mobile: "9560992679", account_group: account_group)
    insert(:peme, member: member, status: "Registered")
    assert %Peme{} = MemberContext.valid_evoucher_reprint?("9560992679", "TEST-ACCOUNT")
  end

  test "valid_evoucher_reprint?/2 returns struct when params are invalid" do
    assert is_nil(MemberContext.valid_evoucher_reprint?("9560992679", "TEST-ACCOUNT"))
  end

  test "get_all_mobile/1 returns list of mobiles based on the given account code" do
    account_group = insert(:account_group, name: "TEST-ACCOUNT", code: "haha")
    member = insert(:member, mobile: "9560992679", account_group: account_group)
    member2 = insert(:member, mobile: "9560992678", account_group: account_group)
    assert [member2.mobile] == MemberContext.get_all_mobile("haha", member.id)
    assert [] == MemberContext.get_all_mobile("hehe", member.id)
  end

  test "update_peme_facility/2 updates peme facility_id when params are valid" do
    peme = insert(:peme)
    facility = insert(:facility)
    assert {:ok, _peme} = MemberContext.update_peme_facility(peme, facility.id)
  end

  test "preload_member_products/1 preloads member products of the giver member" do
    member = insert(:member)
    member = MemberContext.preload_member_products(member)
    assert member.products == []
  end

  test "update_evoucher_member/2 updates member evoucher details" do
    member = insert(:member)
    params = %{
      first_name: "Anton",
      last_name: "Santiago",
      gender: "Male",
      mobile: "9553028576",
      civil_status: "Single"
    }
    assert {:ok, member} = MemberContext.update_evoucher_member(member, params)
    assert member.first_name == "Anton"
    assert member.last_name == "Santiago"
  end

end
