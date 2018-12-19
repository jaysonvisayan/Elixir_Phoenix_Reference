defmodule Innerpeace.Db.Base.AuthorizationContextTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.{
    # Product,
    Member,
    # Account,
    # ProductBenefit,
    # Benefit,
    Facility,
    Practitioner
    # BenefitCoverage,
    # Authorization,
    # ProductCoverage,
    # ProductCoverageFacility,
    # BenefitCoverage,
    # ProductBenefit,
    # AccountProduct,
    # AccountProductBenefit,
    # MemberProduct
  }

  alias Innerpeace.Db.Base.{
    # BenefitContext,
    AuthorizationContext,
    AccountContext
  }

  alias Ecto.UUID

  test "get_member_benefit_coverage* with valid data test" do
    benefit = insert(:benefit, name: "Accenture Benefit")
    coverage = insert(:coverage, description: "OP Laboratory")
    coverage2 = insert(:coverage, description: "OP Consult")
    insert(:benefit_coverage, coverage: coverage, benefit: benefit)
    insert(:benefit_coverage, coverage: coverage2, benefit: benefit)
    account_group = insert(:account_group, code: "C00918")
    account = insert(:account, account_group: account_group, status: "Active")
    member = insert(:member, account_code: account_group.code)
    payor = insert(:payor, name: "Maxicare")
    product = insert(:product, payor: payor)
    account_product = insert(:account_product, account: account, product: product)
    product_benefit = insert(:product_benefit, product: product, benefit: benefit)
    insert(:account_product_benefit, product_benefit: product_benefit, account_product: account_product)
    _account_group = AccountContext.get_account_group(account_group.id)
    member = Repo.get(Member, member.id)

    result = AuthorizationContext.get_member_benefit_coverage(member.id)
    result = [] ++ for test <- result do
      test.description
    end
    assert Enum.sort(result) == Enum.sort(["OP Laboratory", "OP Consult"])
  end

  test "create_authorization with valid params" do
    user = insert(:user)
    params = %{}
    {status, _result} = AuthorizationContext.create_authorization(user.id, params)
    assert status == :ok
  end

  test "list_authorizations" do
    authorization =
      :authorization
      |> insert()
      |> Map.drop([:member, :facility, :coverage, :updated_by, :created_by, :authorization_amounts])

    list =
      AuthorizationContext.list_authorizations
      |> Enum.at(0)
      |> Map.drop([:member, :facility, :coverage, :updated_by, :created_by, :authorization_amounts])

    assert list == authorization
  end

  test "validate member info returns list when attrs is valid" do
    account_group = insert(:account_group, code: "101", name: "AccountName")
    insert(:account, account_group: account_group, status: "Active")
    date = Ecto.Date.cast!("1994-12-25")
    member =
      insert(:member,
             account_code: account_group.code,
             first_name: "Raymond",
             middle_name: " Berango",
             last_name: " Navarro ",
             birthdate: date,
             status: "Active",
             email: "admin@gmail.com",
             mobile: "09210063030")
    params = %{
      "full_name" => "raymond berango navarro",
      "birthdate" => "1994-12-25"
    }

    right = [[
      member.id,
      member.first_name,
      member.middle_name,
      member.last_name,
      member.suffix,
      member.birthdate,
      member.email,
      member.mobile,
      account_group.code,
      account_group.name,
      member.status,
      account_group.id,
      member.expiry_date
    ]]

    assert AuthorizationContext.validate_member_info(params) == right
  end

  test "validate member info returns list when attrs is valid (last name first)" do
    account_group = insert(:account_group, code: "101", name: "AccountName")
    insert(:account, account_group: account_group, status: "Active")
    date = Ecto.Date.cast!("1994-12-25")
    member =
      insert(:member,
             account_code: account_group.code,
             first_name: "Raymond",
             middle_name: " Berango",
             last_name: " Navarro ",
             birthdate: date,
             status: "Active",
             email: "admin@gmail.com",
             mobile: "09210063030")
    params = %{
      "full_name" => "navarro raymond",
      "birthdate" => "1994-12-25"
    }

    right = [[
      member.id,
      member.first_name,
      member.middle_name,
      member.last_name,
      member.suffix,
      member.birthdate,
      member.email,
      member.mobile,
      account_group.code,
      account_group.name,
      member.status,
      account_group.id,
      member.expiry_date
    ]]

    assert AuthorizationContext.validate_member_info(params) == right
  end

  test "validate member info returns list when attrs is valid (no middle name)" do
    account_group = insert(:account_group, code: "101", name: "AccountName")
    insert(:account, account_group: account_group, status: "Active")
    date = Ecto.Date.cast!("1994-12-25")
    member =
      insert(:member,
             account_code: account_group.code,
             first_name: "Raymond",
             middle_name: " Berango",
             last_name: " Navarro ",
             birthdate: date,
             status: "Active",
             email: "admin@gmail.com",
             mobile: "09210063030")
    params = %{
      "full_name" => "raymond navarro",
      "birthdate" => "1994-12-25"
    }

    right = [[
      member.id,
      member.first_name,
      member.middle_name,
      member.last_name,
      member.suffix,
      member.birthdate,
      member.email,
      member.mobile,
      account_group.code,
      account_group.name,
      member.status,
      account_group.id,
      member.expiry_date
    ]]

    assert AuthorizationContext.validate_member_info(params) == right
  end

  test "validate member info returns empty list when attrs is invalid" do
    date = Ecto.Date.cast!("1994-12-25")
    insert(:member, first_name: "Raymond", middle_name: "Berango", last_name: "Navarro", birthdate: date)
    params = %{
      "full_name" => "Raymond Navarro",
      "birthdate" => "1994-12-25"
    }

    assert AuthorizationContext.validate_member_info(params) == {:not_exists}
  end

  #TODO
  # test "validate card details returns member when card details is valid" do
  #   insert(:api_address, name: "PAYORLINK 1.0", address: "https://api.maxicare.com.ph/")
  #   ag = insert(:account_group)
  #   insert(:account, account_group: ag, status: "Active")
  #   member = insert(:member, card_no: "1168011034280092", status: "Active", account_group: ag)
  #   params = %{
  #     "card_number" => "1168011034280092",
  #     "cvv_number" =>  "209"
  #   }

  #   {result, struct} = AuthorizationContext.validate_card(params)

  #   assert result == :true
  #   assert struct.id == member.id
  # end

  # test "validate card details returns nil when card details is invalid" do
  #   insert(:api_address, name: "PAYORLINK 1.0", address: "https://api.maxicare.com.ph/")
  #   params = %{
  #     "card_number" => "1168011034280092",
  #     "cvv_number" =>  "210"
  #   }

  #   result =
  #     params
  #     |> AuthorizationContext.validate_card

  #   assert result == {:invalid_details}
  # end

  test "update_authorization_step3* with valid data updates the authorization" do
    user = insert(:user)
    coverage = insert(:coverage, name: "OP Consult")
    benefit = insert(:benefit)
    product = insert(:product)
    account_group = insert(:account_group, code: "test123")
    account = insert(:account, account_group_id: account_group.id, status: "Active")
    member = insert(:member, account_group: account_group)
    facility = insert(:facility, status: "Affiliated")
    insert(:benefit_coverage, benefit: benefit, coverage: coverage)
    product_benefit = insert(:product_benefit, product: product, benefit: benefit)
    account_product = insert(:account_product, account: account, product: product)
    insert(:account_product_benefit, account_product: account_product, product_benefit: product_benefit)
    insert(:member_product, member: member, account_product: account_product)
    product_coverage = insert(:product_coverage, coverage: coverage, product: product)
    insert(:product_coverage_facility, facility: facility, product_coverage: product_coverage)
    authorization = insert(:authorization, coverage: coverage, facility: facility, member: member)

    params = %{
      "step" => 4,
      "updated_by_id" => user.id,
      "coverage_id" => coverage.id
    }

    {_status, result} = AuthorizationContext.update_authorization_step3(authorization, params, user.id)
    assert Map.has_key?(result, :step)
    assert result.step == 4
  end

  test "update_authorization_step3* with invalid data updates the authorization" do
    insert(:coverage)
    user = insert(:user)
    authorization = insert(:authorization)
    params = %{}
    {status, _result} = AuthorizationContext.update_authorization_step3(authorization, params, user)
    assert status == :invalid_coverage
  end

  test "create_authorization with invalid params" do
    user = insert(:user)
    params = %{}

    {status, _result} = AuthorizationContext.create_authorization(user, params)

    assert status == :error
  end

  test "get_authorization_by_id with valid id" do
    authorization =
      :authorization
      |> insert()
      |> Map.drop([
        :facility,
        :coverage,
        :member,
        :authorization_diagnosis,
        :authorization_practitioners,
        :authorization_amounts,
        :authorization_procedure_diagnoses,
        :authorization_facility_ruvs,
        :authorization_benefit_packages,
        :authorization_practitioner_specializations,
        :logs
      ])
    result =
      authorization.id
      |> AuthorizationContext.get_authorization_by_id()
      |> Map.drop([
        :facility,
        :coverage,
        :member,
        :authorization_diagnosis,
        :authorization_practitioners,
        :authorization_amounts,
        :authorization_procedure_diagnoses,
        :authorization_facility_ruvs,
        :authorization_benefit_packages,
        :authorization_practitioner_specializations,
        :logs
      ])
    assert authorization == result
  end

  test "get_authorization_by_id with invalid id" do
    insert(:authorization)
    {_, id} = UUID.load(UUID.bingenerate())

    result = AuthorizationContext.get_authorization_by_id(id)

    refute _authorization = result
  end

  test "update_authorization_step2 with valid params" do
    authorization = insert(:authorization)
    user = insert(:user)
    facility = insert(:facility)
    params = %{
      "step" => 3,
      "updated_by_id" => "test",
      "facility_id" => facility.id
    }

    {_status, result} = AuthorizationContext.update_authorization_step2(user.id, params, authorization)

    assert result.step == 3
  end

  test "update_authorization_step2 with invalid params" do
    authorization = insert(:authorization)
    user = insert(:user)
    params = %{}

    {status, _result} = AuthorizationContext.update_authorization_step2(user, params, authorization)

    assert status == :error
  end

  test "update_authorization_step4_consult with valid params and validation true" do
    authorization = insert(:authorization)
    user = insert(:user)
    valid = true

    params = %{
      "authorization_id" => authorization.id,
      "consultation_type" => "initial",
      "step" => "5"
    }

    {_status, result} = AuthorizationContext.update_authorization_step4_consult(authorization, params, valid, user.id)

    assert result.status == "Approved"
  end

  test "update_authorization_step4_consult with valid params and validation false" do
    authorization = insert(:authorization)
    user = insert(:user)
    valid = false

    params = %{
      "authorization_id" => authorization.id,
      "consultation_type" => "initial",
      "step" => "5"
    }

    {_status, result} = AuthorizationContext.update_authorization_step4_consult(authorization, params, valid, user.id)

    assert result.status == "For Approval"
  end

  test "update_authorization_step4_consult with invalid params" do
    authorization = insert(:authorization)
    user = insert(:user)
    valid = true

    params = %{
      "authorization_id" => authorization.id,
      "consultation_type" => "",
      "step" => "5"
    }

    {status, _result} = AuthorizationContext.update_authorization_step4_consult(authorization, params, valid, user.id)

    assert status == :error
  end

  test "validate_consultation with true result" do
    coverage = insert(:coverage,
                      name: "OP Consult",
                      description: "OP Consult",
                      code: "OPC",
                      type: "A",
                      status: "A",
                      plan_type: "health_plans")
    diagnosis = insert(:diagnosis)
    benefit = insert(:benefit)
    insert(:benefit_coverage,
            benefit: benefit,
            coverage: coverage)
    insert(:benefit_diagnosis,
            benefit: benefit,
            diagnosis: diagnosis)
    insert(:benefit_limit,
            benefit: benefit,
            limit_type: "Peso",
            limit_amount: 10_000,
            coverages: "OPC")
    product = insert(:product,
                     limit_amount: 100_000)
    product_coverage = insert(:product_coverage,
                              product: product,
                              coverage: coverage)
    insert(:product_coverage_risk_share,
            product_coverage: product_coverage)
    insert(:product_benefit,
            product: product,
            benefit: benefit)
    account_group = insert(:account_group)
    account = insert(:account,
                     account_group: account_group)
    account_product = insert(:account_product,
                             account: account,
                             product: product)
    member = insert(:member)
    insert(:member_product,
            member: member,
            account_product: account_product)
    facility = insert(:facility)
    authorization = insert(:authorization,
                           coverage: coverage,
                           member: member,
                           facility: facility)
    params = %{
      "product_id" => product.id,
      "diagnosis_id" => diagnosis.id,
      "payor_covered" => 400
    }

    valid = AuthorizationContext.validate_consultation(authorization, params)

    assert valid == true
  end

  test "validate_consultation with false result" do
    coverage = insert(:coverage,
                      name: "OP Consult",
                      description: "OP Consult",
                      code: "OPC",
                      type: "A",
                      status: "A",
                      plan_type: "health_plans")
    diagnosis = insert(:diagnosis)
    benefit = insert(:benefit)
    insert(:benefit_coverage,
           benefit: benefit,
           coverage: coverage)
    insert(:benefit_diagnosis,
           benefit: benefit,
           diagnosis: diagnosis)
    insert(:benefit_limit,
           benefit: benefit,
           limit_type: "Peso",
           limit_amount: 10_000,
           coverages: "OPC")
    product = insert(:product,
                     limit_amount: 100_000)
    product_coverage = insert(:product_coverage,
                              product: product,
                              coverage: coverage)
    insert(:product_coverage_risk_share,
            product_coverage: product_coverage)
    insert(:product_benefit,
            product: product,
            benefit: benefit)
    account_group = insert(:account_group)
    account = insert(:account,
                     account_group: account_group)
    account_product = insert(:account_product,
                             account: account,
                             product: product)
    member = insert(:member)
    insert(:member_product,
            member: member,
            account_product: account_product)
    facility = insert(:facility)
    authorization = insert(:authorization,
                           coverage: coverage,
                           member: member,
                           facility: facility)
    params = %{
      "product_id" => product.id,
      "diagnosis_id" => "",
      "payor_covered" => 400
    }

    valid = AuthorizationContext.validate_consultation(authorization, params)

    assert valid == false
  end

  test "create_authorization_diagnosis with valid params" do
    authorization = insert(:authorization)
    diagnosis = insert(:diagnosis)
    user = insert(:user)

    params = %{
      "authorization_id" => authorization.id,
      "diagnosis_id" => diagnosis.id,
    }

    {status, _result} = AuthorizationContext.create_authorization_diagnosis(params, user.id)

    assert status == :ok
  end

  test "create_authorization_diagnosis with invalid params" do
    authorization = insert(:authorization)
    insert(:diagnosis)
    user = insert(:user)

    params = %{
      "authorization_id" => authorization.id,
    }

    {status, _result} = AuthorizationContext.create_authorization_diagnosis(params, user.id)

    assert status == :error
  end

  test "create_authorization_practitioner with valid params" do
    authorization = insert(:authorization)
    practitioner = insert(:practitioner)
    user = insert(:user)

    params = %{
      "authorization_id" => authorization.id,
      "practitioner_id" => practitioner.id,
    }

    {status, _result} = AuthorizationContext.create_authorization_practitioner(params, user.id)

    assert status == :ok
  end

  test "create_authorization_practitioner with invalid params" do
    authorization = insert(:authorization)
    insert(:practitioner)
    user = insert(:user)

    params = %{
      "authorization_id" => authorization.id
    }

    {status, _result} = AuthorizationContext.create_authorization_practitioner(params, user.id)

    assert status == :error
  end

  test "create_authorization_amount with valid params" do
    authorization = insert(:authorization)
    user = insert(:user)

    params = %{
      "authorization_id" => authorization.id,
      "payor_covered" => "50",
      "member_covered" => "150",
      "total_amount" => "200"
    }

    {status, _result} = AuthorizationContext.create_authorization_amount(params, user.id)

    assert status == :ok
  end

  test "create_authorization_amount with invalid params" do
    authorization = insert(:authorization)
    user = insert(:user)

    params = %{
      "authorization_id" => authorization.id
    }

    {status, _result} = AuthorizationContext.create_authorization_amount(params, user.id)

    assert status == :error
  end

  # API
  test "compute_consultation with valid params" do
    params = %{
      "consultation_fee" => "500",
      "copay" => "100",
      "covered" => "60",
      "risk_share_type" => "Copayment",
      "pec" => ""
    }

    computation = AuthorizationContext.compute_consultation(params)
    assert computation.payor == Decimal.new(240.0)
  end
  # End API

  #MemberLink Functions Start
    test "request_op_lab/1 successfully requests loa op laboratory" do
    doctor = insert(:practitioner, first_name: "shane", middle_name: "reid", last_name: "dela rosa")
    facility = insert(:facility, name: "test facility")
    member = insert(:member, first_name: "shane", last_name: "dela rosa", card_no: "123567890")
    insert(:coverage, name: "OP Laboratory")
    params = %{
      "member_id" => member.id,
      "card_number" => "123567890",
      "doctor_id" => doctor.id,
      "provider_id" => facility.id,
      "datetime" => "2018-08-04T12:12:12Z",
      "complaint" => "sample complaint",
      "availment_type" => "test type"
    }
      assert {:ok, _loa} = AuthorizationContext.request_op_lab(params)
    end

    test "request_op_consult/1 successfully requests loa op consult" do
    doctor = insert(:practitioner, first_name: "shane", middle_name: "reid", last_name: "dela rosa")
    facility = insert(:facility, name: "test facility")
    member = insert(:member, first_name: "shane", last_name: "dela rosa", card_no: "123567890")
    coverage = insert(:coverage, name: "OP Consult")
    user = insert(:user)
    params = %{
      "member_id" => member.id,
      "card_number" => "123567890",
      "doctor_id" => doctor.id,
      "provider_id" => facility.id,
      "admission_datetime" => "2018-08-04T12:12:12Z",
      "complaint" => "sample complaint",
      "availment_type" => "test type",
      "coverage_id" => coverage.id
    }
      assert {:ok, _loa} = AuthorizationContext.request_op_consult(user.id, params)
    end

    test "get_provider_by_id returns provider" do
      facility = insert(:facility, name: "test facility", status: "Affiliated")
     assert %Facility{} == AuthorizationContext.get_provider_by_id(facility.id)
    end

    test "get_provider_by_id returns invalid_id" do
      insert(:facility, name: "test facility")
      id = ""
     assert {:invalid_id, "provider"} == AuthorizationContext.get_provider_by_id(id)
    end

    test "get_provider_by_id returns nil" do
      insert(:facility, name: "test facility")
      doctor = insert(:practitioner, first_name: "shane", middle_name: "reid", last_name: "dela rosa")
     assert {nil, "provider"} == AuthorizationContext.get_provider_by_id(doctor.id)
    end

    test "get_practitioner_by_id returns practitioner" do
    doctor = insert(:practitioner, first_name: "shane", middle_name: "reid", last_name: "dela rosa")
     assert %Practitioner{} == AuthorizationContext.get_practitioner_by_id(doctor.id)
    end

    test "get_practitioner_by_id returns invalid_id" do
      insert(:facility, name: "test facility")
      id = ""
     assert {:invalid_id, "practitioner"} == AuthorizationContext.get_practitioner_by_id(id)
    end

    test "get_practitioner_by_id returns nil" do
      facility = insert(:facility, name: "test facility")
      insert(:practitioner, first_name: "shane", middle_name: "reid", last_name: "dela rosa")
     assert {nil, "practitioner"} == AuthorizationContext.get_practitioner_by_id(facility.id)
    end

    test "get_loa by current user returns ok loa" do
      loa = insert(:authorization)
      insert(:practitioner, first_name: "shane", middle_name: "reid", last_name: "dela rosa")
      insert(:facility, name: "test facility")

      assert {:ok, _loa} = AuthorizationContext.get_loa_using_member_id(loa.member_id)
    end

    test "get_loa by current user returns error loa" do
      member = insert(:member, first_name: "Shane", last_name: "Dela Rosa", card_no: "123567890")
      insert(:practitioner, first_name: "shane", middle_name: "reid", last_name: "dela rosa")
      insert(:facility, name: "test facility")

      assert {:error, "loa"} == AuthorizationContext.get_loa_using_member_id(member.id)
    end

  #MemberLink Functions End

  test "insert_otp with valid data" do
    authorization = insert(:authorization)
    {status, auth} = AuthorizationContext.insert_otp(authorization.id)
    assert status == :ok
    assert authorization.id == auth.id
  end

  test "validate_otp with empty otp" do
    authorization = insert(:authorization)
    assert {:otp_not_requested} == AuthorizationContext.validate_otp(authorization.id, "3444")
  end

  test "validate_otp with invalid otp" do
    authorization = insert(:authorization, otp: "1234", otp_expiry: "2018-01-01T12:12:12Z")
    assert {:invalid_otp} == AuthorizationContext.validate_otp(authorization.id, "3444")
  end

  test "validate_otp with expired otp datetime" do
    authorization = insert(:authorization, otp: "1234", otp_expiry: "2018-01-01T12:12:12Z")
    assert {:expired} == AuthorizationContext.validate_otp(authorization.id, "1234")
  end

  test "insert log with valid params" do
    authorization = insert(:authorization, otp: "1234", otp_expiry: "2018-01-01T12:12:12Z")
    user = insert(:user)
    params = %{
      authorization_id: authorization.id,
      user_id: user.id,
      message: "test log"
    }
    assert {:ok, _authorization_log} = AuthorizationContext.insert_log(params)
  end

  test "get_authorization_logs/1 returns logs of given authorization" do
    authorization_log = insert(:authorization_log)
    authorization_logs = AuthorizationContext.get_authorization_logs(authorization_log.authorization.id)
    assert List.first(authorization_logs).id == authorization_log.id
  end

  test "insert log with invalid params" do
    authorization = insert(:authorization, otp: "1234", otp_expiry: "2018-01-01T12:12:12Z")
    user = insert(:user)
    params = %{
      authorization_id: authorization.id,
      user_id: user.id,
    }
    assert {:error, _authorization_log} = AuthorizationContext.insert_log(params)
  end

  # test "get_acu_loa_for_stale/0, no acu loa to be staled" do
  #   coverage = insert(:coverage, name: "ACU", code: "ACU")
  #   facility = insert(:facility, prescription_term: 1)
  #   authorization = insert(:authorization, otp: "1234",
  #                          status: "Approved",
  #                          facility: facility,
  #                          coverage: coverage)
  #   acu_loas = AuthorizationContext.get_acu_loa_for_stale
  #   assert [] == acu_loas
  # end

  # test "get_acu_loa_for_stale/0, get acu loa to be staled" do
  #   coverage = insert(:coverage, name: "ACU", code: "ACU")
  #   facility = insert(:facility, prescription_term: 1)
  #   authorization = insert(:authorization, otp: "1234",
  #                          status: "Approved",
  #                          facility: facility,
  #                          coverage: coverage,
  #                          inserted_at: Timex.subtract(Timex.now, Timex.Duration.from_days(1))
  #   )
  #   acu_loas = AuthorizationContext.get_acu_loa_for_stale
  #   id =
  #     acu_loas
  #     |> Enum.map(fn(map) ->
  #       map.authorization_id
  #     end )
  #     |> List.first()

  #   assert [%{acu_schedule_id: nil, authorization_id: id}] == acu_loas
  # end

  # test "update_acu_status_to_stale/0, no loas found" do
  #   coverage = insert(:coverage, name: "ACU", code: "ACU")
  #   facility = insert(:facility, prescription_term: 1)
  #   authorization = insert(:authorization, otp: "1234",
  #                          status: "Approved",
  #                          facility: facility,
  #                          coverage: coverage)

  #   {:ok, logs} = AuthorizationContext.update_acu_status_to_stale
  #    assert logs.name == "Innerpeace.Db.Base.AuthorizationContext, :update_acu_status_to_stale"
  #    assert logs.message == "No authorizations found to stale."
  # end

  # test "update_acu_status_to_stale/0, error in connecting to providerlink" do
  #   insert(:api_address, address: "https://providerlink-ip-ist.medilink.com.ph",
  #          name: "PROVIDERLINK_2")
  #   coverage = insert(:coverage, name: "ACU", code: "ACU")
  #   facility = insert(:facility, prescription_term: 1)
  #   authorization = insert(:authorization, otp: "1234",
  #                          status: "Approved",
  #                          facility: facility,
  #                          coverage: coverage,
  #                          inserted_at: Timex.subtract(Timex.now, Timex.Duration.from_days(1))
  #   )

  #   {:ok, logs} = AuthorizationContext.update_acu_status_to_stale
  #    assert logs.name == "Innerpeace.Db.Base.AuthorizationContext, :update_acu_status_to_stale"
  #   assert logs.message == "Error occurs when attempting to login in Providerlink"
  # end

  # test "update_acu_status_to_stale/0, update status of acu loa to stale" do
  #   insert(:user, username: "glenTest", password: "glenTest@1", status: "Active")
  #   insert(:api_address, address: "https://providerlink-ip-ist.medilink.com.ph",
  #          name: "PROVIDERLINK_2",
  #          username: "glenTest",
  #          password: "glenTest@1")
  #   coverage = insert(:coverage, name: "ACU", code: "ACU")
  #   facility = insert(:facility, prescription_term: 1)
  #   authorization = insert(:authorization, otp: "1234",
  #                          status: "Approved",
  #                          facility: facility,
  #                          coverage: coverage,
  #                          inserted_at: Timex.subtract(Timex.now, Timex.Duration.from_days(1))
  #   )

  #   {:ok, logs} = AuthorizationContext.update_acu_status_to_stale
  #    assert logs.name == "Innerpeace.Db.Base.AuthorizationContext, :update_acu_status_to_stale"
  #    assert logs.message == "Successfully Updated Loa Statuses To Stale"
  # end
end
