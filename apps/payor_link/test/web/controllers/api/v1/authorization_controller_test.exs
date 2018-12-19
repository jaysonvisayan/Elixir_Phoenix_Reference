defmodule Innerpeace.PayorLink.Web.Api.V1.AuthorizationControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase

  alias PayorLink.Guardian.Plug
  alias Innerpeace.PayorLink.Web.Api.V1.AuthorizationView
  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    # Authorization,
    User
  }
  # alias Innerpeace.Db.Base.Api.AuthorizationContext
  # alias Innerpeace.Db.Base.AuthorizationContext
  alias Innerpeace.Db.Base.{ProductContext, AccountContext}

  setup do
    {:ok, user} = Repo.insert(%User{username: "abbymae", password: "P@ssw0rd"})
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = PayorLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)

    account_group = insert(:account_group, name: "ACCOUNT101", code: "ACC101")
    member = insert(:member, %{
      first_name: "Daniel Eduard",
      last_name: "Andal",
      card_no: "1234567890123456",
      account_group: account_group
    })
    coverage = insert(:coverage,
                      name: "OP Consult",
                      description: "OP Consult",
                      code: "OPC",
                      type: "A",
                      status: "A",
                      plan_type: "health_plans")
    diagnosis = insert(:diagnosis, code: "Z71.1",
                        description: "OTHER BACTERIAL FOODBORNE INTOXICATIONS: Foodborne staphylococcal intoxication",
                        type: "Dreaded")
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Health")

    benefit_limit = insert(:benefit_limit, benefit: benefit,
                          limit_type: "Peso",
                          limit_amount: 1000,
                          coverages: "OPC")

    insert(:benefit_coverage,
           benefit: benefit,
           coverage: coverage)
    insert(:benefit_diagnosis,
           benefit: benefit,
           diagnosis: diagnosis)
    product = insert(:product,
                     limit_amount: 10_000,
                     name: "Maxicare Product 5",
                     standard_product: "Yes", step: "7"
                     )
    product_coverage = insert(:product_coverage,
                              product: product,
                              coverage: coverage)
    product_benefit = insert(:product_benefit,
                              product: product,
                              benefit: benefit)

    insert(:product_benefit_limit,
            product_benefit: product_benefit,
            benefit_limit: benefit_limit,
            limit_type: "Peso",
            limit_amount: 1000)
    account = insert(:account,
                     account_group: account_group,
                     start_date: Ecto.Date.cast!("2010-01-01"),
                     end_date: Ecto.Date.cast!("2019-02-02"),
                     status: "Active")

    account_product = insert(:account_product,
                             account: account,
                             product: product)

    insert(:member_product,
            member: member,
            account_product: account_product, tier: 1)
    facility = insert(:facility, code: "cmc", name: "CALAMBA MEDICAL CENTER",
                      status: "Affiliated",
                      affiliation_date: "2017-11-10",
                      disaffiliation_date: "2018-11-23")
    practitioner = insert(:practitioner,
                          first_name: "Daniel",
                          middle_name: "Murao",
                          last_name: "Andal",
                          effectivity_from: "2017-11-13",
                          effectivity_to: "2019-11-13")

    practitioner_facility = insert(:practitioner_facility,
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
                          practitioner_id: practitioner.id)
    specialization = insert(:specialization, name: "Radiology")

    practitioner_specialization = insert(:practitioner_specialization,
                                          practitioner: practitioner,
                                          specialization: specialization)

    _practitioner_facility_consultation_fee = insert(:practitioner_facility_consultation_fee,
                                              practitioner_facility: practitioner_facility,
                                              practitioner_specialization: practitioner_specialization,
                                              fee: 1000)

    authorization = insert(:authorization,
                           coverage: coverage,
                           member: member,
                           facility: facility)

    {:ok, %{user: user, conn: conn, jwt: jwt,
    coverage: coverage,
      member: member,
      facility: facility,
      authorization: authorization,
      product: product,
      diagnosis: diagnosis,
      practitioner: practitioner,
      practitioner_facility: practitioner_facility,
      product_coverage: product_coverage,
      practitioner_specialization: practitioner_specialization,
      account_product: account_product

    }}
  end

  # test "get api/validate/coverage, validates the member if it is eligible with 3 params scenario1", %{conn: conn, jwt: jwt} do
  #   #             for member_product1 = coverage["ACU", "Inpatient"]
  #   #                           ACU all affiliated facilities
  #   #                           Inpatient Specific Facility[Calamba Medical Center]
  #   #
  #   #             for member_product2 = coverage["ACU", "Inpatient"]
  #   #                           ACU Specific Facility[Calamba Medical Center]
  #   #                           Inpatient Specific Facility[Calamba Medical Center]

  #   account_group = insert(:account_group, name: "Jollibee Worldwide")
  #   account = insert(:account, account_group: account_group)

  #   coverage1 = insert(:coverage, name: "ACU")
  #   coverage2 = insert(:coverage, name: "Inpatient")

  #   facility1 = insert(:facility, code: "880000000000359", name: "Calamba Medical Center", status: "Affiliated")
  #   insert(:facility, code: "880000000006035", name: "Makati Medical Center", status: "Affiliated")

  #   product = insert(:product, name: "LOAPRODUCT1")
  #   insert(:product_coverage, product: product, coverage: coverage1, type: "exception")
  #   product_coverage2 = insert(:product_coverage, product: product, coverage: coverage2, type: "inclusion")
  #   insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
  #   product = ProductContext.get_product!(product.id)

  #   product2 = insert(:product, name: "LOAPRODUCT2")
  #   product2_coverage1 = insert(:product_coverage, product: product2, coverage: coverage1, type: "inclusion")
  #   insert(:product_coverage_facility, product_coverage: product2_coverage1, facility: facility1)
  #   product2_coverage2 = insert(:product_coverage, product: product2, coverage: coverage2, type: "inclusion")
  #   insert(:product_coverage_facility, product_coverage: product2_coverage2, facility: facility1)
  #   product2 = ProductContext.get_product!(product2.id)

  #   account = AccountContext.get_account!(account.id)

  #   account_product1 = insert(:account_product, account: account, product: product)
  #   account_product2 = insert(:account_product, account: account, product: product2)

  #   member = insert(:member, card_no: "1111555588881111", first_name: "Byakuya", last_name: "Kuchiki")
  #   insert(:member_product, member: member, account_product: account_product1)
  #   insert(:member_product, member: member, account_product: account_product2)

  #   params = %{
  #     card_no: "1111555588881111",
  #     facility_code: "880000000006035",
  #     coverage_name: "ACU"
  #   }

  #   conn =
  #     conn
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> get(api_authorization_path(conn, :validate_coverage, params))

  #   assert json_response(conn, 200) == %{"message" => "Eligible"}
  # end

  # test "get api/validate/coverage, validates the member if it is eligible with 3 params scenario2", %{conn: conn, jwt: jwt} do
  #   #             for member_product1 = coverage["ACU", "Inpatient"]
  #   #                           ACU all affiliated facilities
  #   #                           Inpatient Specific Facility: [Calamba Medical Center]
  #   #
  #   #             for member_product2 = coverage["ACU", "Inpatient"]
  #   #                           ACU Specific Facility: [Calamba Medical Center]
  #   #                           Inpatient Specific Facility: [Makati Medical Center]
  #   account_group = insert(:account_group, name: "Jollibee Worldwide")
  #   account = insert(:account, account_group: account_group)

  #   coverage1 = insert(:coverage, name: "ACU")
  #   coverage2 = insert(:coverage, name: "Inpatient")

  #   facility1 = insert(:facility, code: "880000000000359", name: "Calamba Medical Center", status: "Affiliated")
  #   facility2 = insert(:facility, code: "880000000006035", name: "Makati Medical Center", status: "Affiliated")

  #   product = insert(:product, name: "LOAPRODUCT1")
  #   insert(:product_coverage, product: product, coverage: coverage1, type: "exception")
  #   product_coverage2 = insert(:product_coverage, product: product, coverage: coverage2, type: "inclusion")
  #   insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
  #   product = ProductContext.get_product!(product.id)

  #   product2 = insert(:product, name: "LOAPRODUCT2")
  #   insert(:product_coverage, product: product2, coverage: coverage1, type: "inclusion")
  #   insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
  #   insert(:product_coverage, product: product2, coverage: coverage2, type: "inclusion")
  #   insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility2)
  #   product2 = ProductContext.get_product!(product2.id)

  #   account = AccountContext.get_account!(account.id)

  #   account_product1 = insert(:account_product, account: account, product: product)
  #   account_product2 = insert(:account_product, account: account, product: product2)

  #   member = insert(:member, card_no: "1111555588881111", first_name: "Byakuya", last_name: "Kuchiki")
  #   insert(:member_product, member: member, account_product: account_product1)
  #   insert(:member_product, member: member, account_product: account_product2)

  #   params = %{
  #     card_no: "1111555588881111",
  #     facility_code: "880000000006035",
  #     coverage_name: "Inpatient"
  #   }

  #   conn =
  #     conn
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> get(api_authorization_path(conn, :validate_coverage, params))

  #   assert json_response(conn, 200) == %{"message" => "Eligible"}
  # end

  # test "get api/validate/coverage, validates the member if it is eligible with 3 params scenario3",
  # %{conn: conn, jwt: jwt} do
  #   #             for member_product1 = coverage["ACU", "Inpatient"]
  #   #                           ACU all affiliated facilities
  #   #                           Inpatient Specific Facility: [Calamba Medical Center]
  #   #
  #   #             for member_product2 = coverage["ACU", "Inpatient"]
  #   #                           ACU Specific Facility: [Calamba Medical Center]
  #   #                           Inpatient Specific Facility: [Makati Medical Center]
  #   account_group = insert(:account_group, name: "Jollibee Worldwide")
  #   account = insert(:account, account_group: account_group)

  #   coverage1 = insert(:coverage, name: "ACU")
  #   coverage2 = insert(:coverage, name: "Inpatient")
  #   coverage3 = insert(:coverage, name: "RUV")

  #   facility1 = insert(:facility, code: "880000000000359", name: "Calamba Medical Center", status: "Affiliated")
  #   facility2 = insert(:facility, code: "880000000006035", name: "Makati Medical Center", status: "Affiliated")

  #   product = insert(:product, name: "LOAPRODUCT1")
  #   product_coverage1 = insert(:product_coverage, product: product, coverage: coverage1, type: "exception")
  #   product_coverage2 = insert(:product_coverage, product: product, coverage: coverage2, type: "inclusion")
  #   product_coverage3 = insert(:product_coverage, product: product, coverage: coverage3, type: "inclusion")
  #   product_coverage_facility = insert(:product_coverage_facility, product_coverage: product_coverage3,
  #   facility: facility1)
  #   product_coverage_facility = insert(:product_coverage_facility, product_coverage: product_coverage2,
  #   facility: facility1)
  #   product = ProductContext.get_product!(product.id)

  #   product2 = insert(:product, name: "LOAPRODUCT2")
  #   product2_coverage1 = insert(:product_coverage, product: product2, coverage: coverage1, type: "inclusion")
  #   product_coverage_facility = insert(:product_coverage_facility, product_coverage: product_coverage2,
  #   facility: facility1)
  #   product2_coverage2 = insert(:product_coverage, product: product2, coverage: coverage2, type: "inclusion")
  #   product_coverage_facility = insert(:product_coverage_facility, product_coverage: product_coverage2,
  #   facility: facility2)
  #   product2 = ProductContext.get_product!(product2.id)

  #   account = AccountContext.get_account!(account.id)

  #   account_product1 = insert(:account_product, account: account, product: product)
  #   account_product2 = insert(:account_product, account: account, product: product2)

  #   member = insert(:member, card_no: "1111555588881111", first_name: "Byakuya", last_name: "Kuchiki")
  #   member_product1 = insert(:member_product, member: member, account_product: account_product1)
  #   member_product2 = insert(:member_product, member: member, account_product: account_product2)

  #   params = %{
  #     card_no: "1111555588881111",
  #     facility_code: "880000000006035",
  #     coverage_name: "RUV"
  #   }

  #   conn =
  #     conn
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> get(api_authorization_path(conn, :validate_coverage, params))

  #   assert json_response(conn, 400) == %{"error" => %{"message" => "facility is not covered by the given coverage"}}

  # end

  test "post api/validate/coverage, validates the member if it is eligible with invalid card no params", %{conn: conn, jwt: jwt} do
    account_group = insert(:account_group, name: "Jollibee Worldwide")
    account = insert(:account, account_group: account_group)

    coverage1 = insert(:coverage, name: "ACU")
    coverage2 = insert(:coverage, name: "Inpatient")

    facility1 = insert(:facility, code: "880000000000359", name: "Calamba Medical Center", status: "Affiliated")
    facility2 = insert(:facility, code: "880000000006035", name: "Makati Medical Center", status: "Affiliated")

    product = insert(:product, name: "LOAPRODUCT1")
    insert(:product_coverage, product: product, coverage: coverage1, type: "exception")
    product_coverage2 = insert(:product_coverage, product: product, coverage: coverage2, type: "inclusion")
    insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
    product = ProductContext.get_product!(product.id)

    product2 = insert(:product, name: "LOAPRODUCT2")
    insert(:product_coverage, product: product2, coverage: coverage1, type: "inclusion")
    insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
    insert(:product_coverage, product: product2, coverage: coverage2, type: "inclusion")
    insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility2)
    product2 = ProductContext.get_product!(product2.id)

    account = AccountContext.get_account!(account.id)

    account_product1 = insert(:account_product, account: account, product: product)
    account_product2 = insert(:account_product, account: account, product: product2)

    member = insert(:member, card_no: "1111555588881111", first_name: "Byakuya", last_name: "Kuchiki")
    insert(:member_product, member: member, account_product: account_product1)
    insert(:member_product, member: member, account_product: account_product2)

    params = %{
      card_no: "1111555588881111s",
      facility_code: "880000000006035",
      coverage_name: "Inpatient"
    }

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_authorization_path(conn, :validate_coverage, params))

      assert json_response(conn, 400) == %{"error" => %{"message" => "Card number does not exist"}}
  end

  test "post api/validate/coverage, validates the member if it is eligible with invalid facility code param", %{conn: conn, jwt: jwt} do
    account_group = insert(:account_group, name: "Jollibee Worldwide")
    account = insert(:account, account_group: account_group)

    coverage1 = insert(:coverage, name: "ACU")
    coverage2 = insert(:coverage, name: "Inpatient")

    facility1 = insert(:facility, code: "880000000000359", name: "Calamba Medical Center", status: "Affiliated")
    facility2 = insert(:facility, code: "880000000006035", name: "Makati Medical Center", status: "Affiliated")

    product = insert(:product, name: "LOAPRODUCT1")
    insert(:product_coverage, product: product, coverage: coverage1, type: "exception")
    product_coverage2 = insert(:product_coverage, product: product, coverage: coverage2, type: "inclusion")
    insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
    product = ProductContext.get_product!(product.id)

    product2 = insert(:product, name: "LOAPRODUCT2")
    insert(:product_coverage, product: product2, coverage: coverage1, type: "inclusion")
    insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
    insert(:product_coverage, product: product2, coverage: coverage2, type: "inclusion")
    insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility2)
    product2 = ProductContext.get_product!(product2.id)

    account = AccountContext.get_account!(account.id)

    account_product1 = insert(:account_product, account: account, product: product)
    account_product2 = insert(:account_product, account: account, product: product2)

    member = insert(:member, card_no: "1111555588881111", first_name: "Byakuya", last_name: "Kuchiki", status: "Active")
    insert(:member_product, member: member, account_product: account_product1)
    insert(:member_product, member: member, account_product: account_product2)

    params = %{
      card_no: "1111555588881111",
      facility_code: "880000000006035rwelirh",
      coverage_name: "Inpatient"
    }

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_authorization_path(conn, :validate_coverage, params))

      assert json_response(conn, 400) == %{"error" => %{"message" => "Facility code not found."}}
  end

  test "post api/validate/coverage, validates the member if it is eligible with invalid coverage name param", %{conn: conn, jwt: jwt} do
    account_group = insert(:account_group, name: "Jollibee Worldwide")
    account = insert(:account, account_group: account_group)

    coverage1 = insert(:coverage, name: "ACU")
    coverage2 = insert(:coverage, name: "Inpatient")

    facility1 = insert(:facility, code: "880000000000359", name: "Calamba Medical Center", status: "Affiliated")
    facility2 = insert(:facility, code: "880000000006035", name: "Makati Medical Center", status: "Affiliated")

    product = insert(:product, name: "LOAPRODUCT1")
    insert(:product_coverage, product: product, coverage: coverage1, type: "exception")
    product_coverage2 = insert(:product_coverage, product: product, coverage: coverage2, type: "inclusion")
    insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
    product = ProductContext.get_product!(product.id)

    product2 = insert(:product, name: "LOAPRODUCT2")
    insert(:product_coverage, product: product2, coverage: coverage1, type: "inclusion")
    insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
    insert(:product_coverage, product: product2, coverage: coverage2, type: "inclusion")
    insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility2)
    product2 = ProductContext.get_product!(product2.id)

    account = AccountContext.get_account!(account.id)

    account_product1 = insert(:account_product, account: account, product: product)
    account_product2 = insert(:account_product, account: account, product: product2)

    member = insert(:member, card_no: "1111555588881111", first_name: "Byakuya", last_name: "Kuchiki", status: "Active")
    insert(:member_product, member: member, account_product: account_product1)
    insert(:member_product, member: member, account_product: account_product2)

    params = %{
      card_no: "1111555588881111",
      facility_code: "880000000006035",
      coverage_name: "Inpatientbessy"
    }

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_authorization_path(conn, :validate_coverage, params))

      assert json_response(conn, 400) == %{"error" => %{"message" => "Coverage name does not exist"}}
  end

  # defp render_json(template, assigns) do
  #   assigns = Map.new(assigns)

  #   Innerpeace.PayorLink.Web.Api.V1.PractitionerView.render(template, assigns)
  #   |> Poison.encode!
  #   |> Poison.decode!
  # end

  # defp render_json_error(template, assigns) do
  #   assigns = Map.new(assigns)

  #   Innerpeace.PayorLink.Web.Api.V1.ErrorView.render(template, assigns)
  #   |> Poison.encode!
  #   |> Poison.decode!
  # end

   # test "request_op_consult/1 successfully requests loa op consult", %{conn: conn, jwt: jwt,
   #  practitioner: practitioner, diagnosis: diagnosis, member: member,
   #  facility: facility, product: product,
   #   product_coverage: product_coverage, authorization: authorization,
   #  practitioner_specialization: practitioner_specialization} do
   #  insert(:product_coverage_risk_share,
   #         product_coverage: product_coverage,
   #         af_type: "Copayment",
   #         af_covered_amount: 80,
   #         naf_reimbursable: "No",
   #         naf_type: "Copayment",
   #         naf_covered_amount: 80,
   #         af_value_amount: 100,
   #         naf_value_amount: 100)
   #  exclusion = insert(:exclusion, coverage: "Pre-existing Condition", code: "test", name: "test")
   #    insert(:exclusion_duration, exclusion: exclusion, disease_type: "Dreaded",
   #           duration: 12, percentage: 50)
   #  insert(:exclusion_disease, exclusion: exclusion, disease: diagnosis)
   #    insert(:product_exclusion, product: product, exclusion: exclusion)

   #    params = %{
   #      "member_id" => member.id,
   #      "card_number" => "123456789012",
   #      "authorization_id" => authorization.id,
   #      "doctor_id" => practitioner_specialization.id,
   #      "diagnosis_id" => diagnosis.id,
   #      "provider_id" => facility.id,
   #      "datetime" => "09/30/2017 10:00 AM",
   #      "chief_complaint" => "sample complaint"
   #    }
   #  conn =
   #    conn
   #    |> put_req_header("authorization", "bearer #{jwt}")
   #    |> post(api_authorization_path(conn, :request_op_consult, params))
   #  loa = conn.assigns.loa
   #  assert json_response(conn, 200) == render_json2("loa.json", loa: loa)

   # end

test "request_op_consult/1 with invalid card number returns error message", %{conn: conn, jwt: jwt,
    practitioner_specialization: practitioner_specialization, diagnosis: diagnosis, member: member,
    facility: facility} do
    params = %{
      "member_id" => member.id,
      "card_number" => "1234567d89012345a6",
      "practitioner_specialization_id" => practitioner_specialization.id,
      "facility_id" => facility.id,
      "diagnosis_id" => diagnosis.id,
      "datetime" => "09/30/2017 10:00 AM",
      "consultation_type" => "initial",
      "chief_complaint" => "Sample Complaint",
      "availment_type" => "Test Type",
      "origin" => "payorlink"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_authorization_path(conn, :request_op_consult, params))
    assert json_response(conn, 400) == %{"message" => "Card number should be numberic only", "code" => 400}
  end

  test "request_op_consult/1 with invalid params returns Invalid Provider", %{conn: conn, jwt: jwt,
    practitioner_specialization: practitioner_specialization, diagnosis: diagnosis, member: member} do
    params = %{
      "member_id" => member.id,
      "card_number" => "1234567890123456",
      "practitioner_specialization_id" => practitioner_specialization.id,
      "diagnosis_id" => diagnosis.id,
      "datetime" => "09/30/2017 10:00 AM",
      "consultation_type" => "initial",
      "chief_complaint" => "",
      "origin" => "payorlink",
      "facility_id" => "123"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_authorization_path(conn, :request_op_consult, params))
    assert json_response(conn, 400) == %{"message" => "Invalid Facility ID", "code" => 400}
  end

  test "request_op_consult/1 with invalid params returns Practitioner Specialization Not Found", %{conn: conn, jwt: jwt,
    diagnosis: diagnosis, member: member, facility: facility} do
    params = %{
      "member_id" => member.id,
      "card_number" => "1234567890123456",
      "datetime" => "09/30/2017 10:00 AM",
      "consultation_type" => "initial",
      "diagnosis_id" => diagnosis.id,
      "chief_complaint" => "",
      "practitioner_specialization_id" => facility.id,
      "facility_id" => facility.id,
      "origin" => "payorlink"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_authorization_path(conn, :request_op_consult, params))
    assert json_response(conn, 400) == %{"message" => "Practitioner Specialization does not exist", "code" => 400}
  end

  test "request_op_consult/1 with invalid params returns Invalid Member", %{conn: conn, jwt: jwt,
    practitioner_specialization: practitioner_specialization, diagnosis: diagnosis, facility: facility} do
    params = %{
      "card_number" => "1234567890123456",
      "datetime" => "09/30/2017 10:00 AM",
      "consultation_type" => "initial",
      "practitioner_specialization_id" => practitioner_specialization.id,
      "diagnosis_id" => diagnosis.id,
      "chief_complaint" => "",
      "facility_id" => facility.id,
      "origin" => "payorlink",
      "member_id" => "123"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_authorization_path(conn, :request_op_consult, params))
    assert json_response(conn, 400) == %{"message" => "Invalid Member ID", "code" => 400}
  end

  test "request_op_consult/1 with invalid params returns Provider Not Found", %{conn: conn, jwt: jwt,
    practitioner_specialization: practitioner_specialization, diagnosis: diagnosis, member: member} do
    params = %{
      "member_id" => member.id,
      "card_number" => "1234567890123456",
      "datetime" => "09/30/2017 10:00 AM",
      "consultation_type" => "initial",
      "practitioner_specialization_id" => practitioner_specialization.id,
      "diagnosis_id" => diagnosis.id,
      "chief_complaint" => "",
      "facility_id" => member.id,
      "origin" => "payorlink"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_authorization_path(conn, :request_op_consult, params))
    assert json_response(conn, 400) == %{"message" => "Facility does not exist.", "code" => 400}
  end

  test "request_op_consult/1 with invalid params returns Invalid DateTime Format", %{conn: conn, jwt: jwt,
    practitioner_specialization: practitioner_specialization, diagnosis: diagnosis, member: member,
    facility: facility} do
    params = %{
      "member_id" => member.id,
      "card_number" => "1234567890123456",
      "practitioner_specialization_id" => practitioner_specialization.id,
      "diagnosis_id" => diagnosis.id,
      "consultation_type" => "initial",
      "chief_complaint" => "",
      "facility_id" => facility.id,
      "origin" => "payorlink",
      "datetime" => "123"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_authorization_path(conn, :request_op_consult, params))
    assert json_response(conn, 400) == %{"message" => "Invalid DateTime Format", "code" => 400}
  end

  # test "request_op_consult/1 with card number not affiliated", %{conn: conn, jwt: jwt,
  #   practitioner_specialization: practitioner_specialization, diagnosis: diagnosis, member: member,
  #   facility: facility} do
  #   params = %{
  #     "member_id" => member.id,
  #     "card_number" => "1234567890123456",
  #     "practitioner_specialization_id" => practitioner_specialization.id,
  #     "diagnosis_id" => diagnosis.id,
  #     "datetime" => "09/30/2017 10:00 AM",
  #     "consultation_type" => "initial",
  #     "chief_complaint" => "",
  #     "facility_id" => facility.id,
  #     "origin" => "payorlink",
  #     "chief_complaint" => "sample complaint"
  #   }
  #   conn =
  #     conn
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> post(api_authorization_path(conn, :request_op_consult, params))
  #   assert json_response(conn, 400) == %{"message" => "Card number not affiliated with member", "code" => 400}
  # end

   test "request_op_consult/1 with member without product return no product in member",
   %{conn: conn, jwt: jwt, diagnosis: diagnosis,
     practitioner_specialization: practitioner_specialization,
     facility: facility} do
    member = insert(:member, first_name: "Shane", last_name: "Dela Rosa", card_no: "1234567890123456")
    params = %{
      "member_id" => member.id,
      "card_number" => "1234567890123456",
      "practitioner_specialization_id" => practitioner_specialization.id,
      "diagnosis_id" => diagnosis.id,
      "datetime" => "09/30/2017 10:00 AM",
      "consultation_type" => "initial",
      "chief_complaint" => "",
      "facility_id" => facility.id,
      "origin" => "payorlink"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_authorization_path(conn, :request_op_consult, params))
    assert json_response(conn, 400) == %{"message" => "There's no Product in Member", "code" => 400}
  end

  test "insert_utilization successfully inserted", %{conn: conn, jwt: jwt, member: member, facility: facility} do
    params = %{
      "member_card_no": member.card_no,
      "facility_code": facility.code,
      "coverage_code": "OPC",
      "consultation_type": "initial",
      "chief_complaint": "chief_complaint",
      "chief_complaint_others": "chief_complaint",
      "internal_remarks": "remarks",
      "assessed_amount": 1000,
      "total_amount": 1000,
      "status": "Approve",
      "version": 1,
      "admission_datetime": "2017-10-10 10:00 AM",
      "discharge_datetime": "2017-10-10 10:00 AM",
      "availment_type": "type",
      "reason": "123123123",
      "pre_existing_percentage": 50,
      "payor_covered": 1000,
      "member_covered": 1000,
      "company_covered": 0,
      "vat_amount": 200,
      "special_approval_amount": 0
    }

    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> post(api_authorization_path(conn, :insert_utilization, params))
    loa = conn.assigns.loa
    assert json_response(conn, 200) == render_json2("loa.json", loa: loa)
  end

  test "insert_utilization returns facility not found", %{conn: conn, jwt: jwt, member: member} do
    params = %{
      "member_card_no": member.card_no,
      "facility_code": member.card_no,
      "coverage_code": "OPC",
      "consultation_type": "initial",
      "chief_complaint": "chief_complaint",
      "chief_complaint_others": "chief_complaint",
      "internal_remarks": "remarks",
      "assessed_amount": 1000,
      "total_amount": 1000,
      "status": "Approve",
      "version": 1,
      "admission_datetime": "09/30/2017 10:00 AM",
      "discharge_datetime": "10/10/2017 10:00 AM",
      "availment_type": "type",
      "reason": "123123123",
      "pre_existing_percentage": 50,
      "payor_covered": 1000,
      "member_covered": 1000,
      "company_covered": 0,
      "vat_amount": 200,
      "special_approval_amount": 0
    }

    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> post(api_authorization_path(conn, :insert_utilization, params))
    assert json_response(conn, 400) == %{"message" => "Facility Not Found", "code" => 400}
  end

  test "insert_utilization returns member not found", %{conn: conn, jwt: jwt, facility: facility} do
    params = %{
      "member_card_no": facility.code,
      "facility_code": facility.code,
      "coverage_code": "OPC",
      "consultation_type": "initial",
      "chief_complaint": "chief_complaint",
      "chief_complaint_others": "chief_complaint",
      "internal_remarks": "remarks",
      "assessed_amount": 1000,
      "total_amount": 1000,
      "status": "Approve",
      "version": 1,
      "admission_datetime": "09/30/2017 10:00 AM",
      "discharge_datetime": "10/10/2017 10:00 AM",
      "availment_type": "type",
      "reason": "123123123",
      "pre_existing_percentage": 50,
      "payor_covered": 1000,
      "member_covered": 1000,
      "company_covered": 0,
      "vat_amount": 200,
      "special_approval_amount": 0
    }

    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> post(api_authorization_path(conn, :insert_utilization, params))
    assert json_response(conn, 400) == %{"message" => "Member Not Found", "code" => 400}
  end

  defp render_json2(template, assigns) do
    assigns = Map.new(assigns)

    view = AuthorizationView.render(template, assigns)
    view
    |> Poison.encode!
    |> Poison.decode!
  end

  # ACU
  # test "request_acu with valid params", %{conn: conn, jwt: jwt} do
  #   account_group = insert(:account_group, name: "ACCOUNT01", code: "ACC01")
  #   member = insert(:member, %{
  #     first_name: "Juan",
  #     last_name: "Dela Cruz",
  #     card_no: "123456789010",
  #     account_group: account_group,
  #     effectivity_date: Ecto.Date.cast!("2017-01-01"),
  #     expiry_date: Ecto.Date.cast!("2019-02-02"),
  #     gender: "Male"
  #   })
  #   coverage = insert(:coverage,
  #                     name: "ACU",
  #                     description: "ACU",
  #                     code: "ACU",
  #                     type: "A",
  #                     status: "A",
  #                     plan_type: "riders")
  #   diagnosis = insert(:diagnosis, code: "Z00.0",
  #                       description: "Test Diagnosis",
  #                       type: "Non-Dreaded")
  #   benefit = insert(:benefit, code: "B01",
  #                    name: "ACU Benefit",
  #                    category: "Riders",
  #                    acu_type: "Regular",
  #                    acu_coverage: "Outpatient")
  #   benefit_limit = insert(:benefit_limit,
  #                          benefit: benefit,
  #                          limit_type: "Sessions",
  #                          limit_session: 1,
  #                          coverages: "ACU")
  #   package = insert(:package,
  #                    code: "Package01",
  #                    name: "Package01")
  #   insert(:benefit_package,
  #          benefit: benefit,
  #          package: package)
  #   insert(:benefit_coverage,
  #          benefit: benefit,
  #          coverage: coverage)
  #   insert(:benefit_diagnosis,
  #          benefit: benefit,
  #          diagnosis: diagnosis)
  #   product = insert(:product,
  #                    limit_amount: 100_000,
  #                    name: "Product01",
  #                    standard_product: "Yes", step: "7")
  #   procedure = insert(:procedure, code: "83498",
  #                      description: "HYDROXYPROGESTERONE, 17-D",
  #                      type: "Diagnostic")
  #   payor_procedure = insert(:payor_procedure, code: "LAB0503004",
  #                      description: "17 HYDROXY PROGESTERONE",
  #                      is_active: true, procedure: procedure)
  #   benefit_procedure = insert(:benefit_procedure,
  #                            benefit: benefit,
  #                            procedure: payor_procedure,
  #                            age_from: 0,
  #                            age_to: 100,
  #                            gender: "Male")
  #   product_coverage = insert(:product_coverage,
  #                             product: product,
  #                             coverage: coverage)
  #   product_benefit = insert(:product_benefit,
  #                             product: product,
  #                             benefit: benefit)
  #   insert(:product_benefit_limit,
  #           product_benefit: product_benefit,
  #           benefit_limit: benefit_limit,
  #           limit_type: "Sessions",
  #           limit_session: 1)
  #   account = insert(:account,
  #                    account_group: account_group,
  #                    start_date: Ecto.Date.cast!("2017-01-01"),
  #                    end_date: Ecto.Date.cast!("2019-02-02"),
  #                    status: "Active")
  #   account_product = insert(:account_product,
  #                            account: account,
  #                            product: product)
  #   insert(:member_product,
  #           member: member,
  #           account_product: account_product, tier: 1)
  #   facility = insert(:facility, code: "myh",
  #                     name: "MYHEALTH CLINIC - SM NORTH EDSA",
  #                     status: "Affiliated",
  #                     affiliation_date: "2017-11-10",
  #                     disaffiliation_date: "2018-11-23")
  #   insert(:package_facility, package: package, facility: facility, rate: 1000)
  #   authorization = insert(:authorization, member: member,
  #                          facility: facility, coverage: coverage,
  #                          status: "Draft", step: 3)
  #   package_payor_procedure = insert(:package_payor_procedure,
  #     payor_procedure: payor_procedure,
  #     package: package,
  #     male: true,
  #     female: true,
  #     age_from: 0,
  #     age_to: 100
  #   )

  #   params = %{
  #     "authorization_id" => authorization.id,
  #     "card_no" => member.card_no,
  #     "facility_code" => facility.code,
  #     "coverage_code" => coverage.code,
  #     "admission_date" => "",
  #     "discharge_date" => "",
  #     "origin" => "providerlink",
  #     "acu_schedule_id" => nil
  #   }

  #   conn =
  #     conn
  #     |> put_req_header("authorization", "bearer #{jwt}")
  #     |> post(api_authorization_path(conn, :request_acu, params))

  #   loa = conn.assigns.loa
  #   assert json_response(conn, 200) == render_json2("acu_loa.json", loa: loa)
  # end

  test "request_acu without package facility rate setup", %{
    conn: conn, jwt: jwt
  } do
    account_group = insert(:account_group, name: "ACCOUNT01", code: "ACC01")
    member = insert(:member, %{
      first_name: "Juan",
      last_name: "Dela Cruz",
      card_no: "123456789010",
      account_group: account_group,
      effectivity_date: Ecto.Date.cast!("2017-01-01"),
      expiry_date: Ecto.Date.cast!("2019-02-02"),
      gender: "Male"
    })
    coverage = insert(:coverage,
                      name: "ACU",
                      description: "ACU",
                      code: "ACU",
                      type: "A",
                      status: "A",
                      plan_type: "riders")
    diagnosis = insert(:diagnosis, code: "Z00.0",
                        description: "Test Diagnosis",
                        type: "Non-Dreaded")
    benefit = insert(:benefit, code: "B01",
                     name: "ACU Benefit",
                     category: "Riders",
                     acu_type: "Regular",
                     acu_coverage: "Outpatient")
    benefit_limit = insert(:benefit_limit,
                           benefit: benefit,
                           limit_type: "Sessions",
                           limit_session: 1,
                           coverages: "ACU")
    package = insert(:package,
                     code: "Package01",
                     name: "Package01")
    procedure = insert(:procedure, code: "83498",
                       description: "HYDROXYPROGESTERONE, 17-D",
                       type: "Diagnostic")
    payor_procedure = insert(:payor_procedure, code: "LAB0503004",
                       description: "17 HYDROXY PROGESTERONE",
                       is_active: true, procedure: procedure)
    insert(:benefit_procedure,
                             benefit: benefit,
                             procedure: payor_procedure,
                             age_from: 0,
                             age_to: 100,
                             gender: "Male")
    benefit_package = insert(:benefit_package,
           benefit: benefit,
           package: package,
           age_from: 0,
           age_to: 100,
           male: true,
           female: true
    )
    insert(:benefit_coverage,
           benefit: benefit,
           coverage: coverage)
    insert(:benefit_diagnosis,
           benefit: benefit,
           diagnosis: diagnosis)
    product = insert(:product,
                     limit_amount: 100_000,
                     name: "Product01",
                     standard_product: "Yes", step: "7")
    insert(:product_coverage,
                              product: product,
                              coverage: coverage,
                              type: "exception")
    product_benefit = insert(:product_benefit,
                              product: product,
                              benefit: benefit)
    insert(:product_benefit_limit,
            product_benefit: product_benefit,
            benefit_limit: benefit_limit,
            limit_type: "Sessions",
            limit_session: 1)
    account = insert(:account,
                     account_group: account_group,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2019-02-02"),
                     status: "Active")
    account_product = insert(:account_product,
                             account: account,
                             product: product)
    insert(:member_product,
            member: member,
            account_product: account_product, tier: 1)
    facility = insert(:facility, code: "myh",
                      name: "MYHEALTH CLINIC - SM NORTH EDSA",
                      status: "Affiliated",
                      affiliation_date: "2017-11-10",
                      disaffiliation_date: "2018-11-23")
    authorization = insert(:authorization, member: member,
                           facility: facility, coverage: coverage,
                           status: "Draft", step: 3)

    params = %{
      "authorization_id" => authorization.id,
      "card_no" => member.card_no,
      "facility_code" => facility.code,
      "coverage_code" => coverage.code,
      "admission_date" => "",
      "discharge_date" => "",
      "origin" => "providerlink",
      "benefit_package_id" => benefit_package.id
    }

    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> post(api_authorization_path(conn, :request_acu, params))

    assert json_response(conn, 400) ==
      %{
        "message" => "Member is not eligible to avail ACU in this Hospital / Clinic.",
        "code" => 400
      }
  end

  test "request_acu with member already availed acu", %{conn: conn, jwt: jwt}
  do
    account_group = insert(:account_group, name: "ACCOUNT01", code: "ACC01")
    member = insert(:member, %{
      first_name: "Juan",
      last_name: "Dela Cruz",
      card_no: "123456789010",
      account_group: account_group,
      effectivity_date: Ecto.Date.cast!("2017-01-01"),
      expiry_date: Ecto.Date.cast!("2019-02-02"),
      gender: "Male"
    })
    coverage = insert(:coverage,
                      name: "ACU",
                      description: "ACU",
                      code: "ACU",
                      type: "A",
                      status: "A",
                      plan_type: "riders")
    diagnosis = insert(:diagnosis, code: "Z00.0",
                        description: "Test Diagnosis",
                        type: "Non-Dreaded")
    benefit = insert(:benefit, code: "B01",
                     name: "ACU Benefit",
                     category: "Riders",
                     acu_type: "Regular",
                     acu_coverage: "Outpatient")
    benefit_limit = insert(:benefit_limit,
                           benefit: benefit,
                           limit_type: "Sessions",
                           limit_session: 1,
                           coverages: "ACU")
    package = insert(:package,
                     code: "Package01",
                     name: "Package01")
    procedure = insert(:procedure, code: "83498",
                       description: "HYDROXYPROGESTERONE, 17-D",
                       type: "Diagnostic")
    payor_procedure = insert(:payor_procedure, code: "LAB0503004",
                       description: "17 HYDROXY PROGESTERONE",
                       is_active: true, procedure: procedure)
    insert(:benefit_procedure,
                             benefit: benefit,
                             procedure: payor_procedure,
                             age_from: 0,
                             age_to: 100,
                             gender: "Male")
    benefit_package = insert(:benefit_package,
           benefit: benefit,
           package: package,
           age_from: 0,
           age_to: 100,
           male: true,
           female: true
    )
    insert(:benefit_coverage,
           benefit: benefit,
           coverage: coverage)
    insert(:benefit_diagnosis,
           benefit: benefit,
           diagnosis: diagnosis)
    product = insert(:product,
                     limit_amount: 100_000,
                     name: "Product01",
                     standard_product: "Yes", step: "7")
    insert(:product_coverage,
                              product: product,
                              coverage: coverage,
                              type: "exception")
    product_benefit = insert(:product_benefit,
                              product: product,
                              benefit: benefit)
    insert(:product_benefit_limit,
            product_benefit: product_benefit,
            benefit_limit: benefit_limit,
            limit_type: "Sessions",
            limit_session: 1)
    account = insert(:account,
                     account_group: account_group,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2019-02-02"),
                     status: "Active")
    account_product = insert(:account_product,
                             account: account,
                             product: product)
    insert(:member_product,
            member: member,
            account_product: account_product, tier: 1)
    facility = insert(:facility, code: "myh",
                      name: "MYHEALTH CLINIC - SM NORTH EDSA",
                      status: "Affiliated",
                      affiliation_date: "2017-11-10",
                      disaffiliation_date: "2018-11-23")
    insert(:package_facility, package: package, facility: facility, rate: 1000)
    auth = insert(:authorization, member: member, facility: facility,
           coverage: coverage, status: "Approved", step: 5)
    insert(:authorization_benefit_package, authorization_id: auth.id, benefit_package_id: benefit_package.id)
    authorization = insert(:authorization, member: member,
                           facility: facility, coverage: coverage,
                           status: "Draft", step: 3)

    params = %{
      "authorization_id" => authorization.id,
      "card_no" => member.card_no,
      "facility_code" => facility.code,
      "coverage_code" => coverage.code,
      "admission_date" => "",
      "discharge_date" => "",
      "origin" => "providerlink",
      "benefit_package_id" => benefit_package.id
    }

    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> post(api_authorization_path(conn, :request_acu, params))

    assert json_response(conn, 400) ==
      %{
        "message" => "Member's ACU packages has been approved or availed",
        "code" => 400
      }
  end

  # test "get_acu_details with valid params", %{conn: conn, jwt: jwt} do
  #   account_group = insert(:account_group, name: "ACCOUNT01", code: "ACC01")
  #   member = insert(:member, %{
  #     first_name: "Juan",
  #     last_name: "Dela Cruz",
  #     card_no: "123456789010",
  #     account_group: account_group,
  #     effectivity_date: Ecto.Date.cast!("2017-01-01"),
  #     expiry_date: Ecto.Date.cast!("2019-02-02"),
  #     birthdate: Ecto.Date.cast!("1990-01-01"),
  #     gender: "Male"
  #   })
  #   coverage = insert(:coverage,
  #                     name: "ACU",
  #                     description: "ACU",
  #                     code: "ACU",
  #                     type: "A",
  #                     status: "A",
  #                     plan_type: "riders")
  #   diagnosis = insert(:diagnosis, code: "Z00.0",
  #                       description: "Test Diagnosis",
  #                       type: "Non-Dreaded")
  #   procedure = insert(:procedure, code: "83498",
  #                      description: "HYDROXYPROGESTERONE, 17-D",
  #                      type: "Diagnostic")
  #   payor_procedure = insert(:payor_procedure, code: "LAB0503004",
  #                      description: "17 HYDROXY PROGESTERONE",
  #                      is_active: true, procedure: procedure)
  #   benefit = insert(:benefit, code: "B01",
  #                    name: "ACU Benefit",
  #                    category: "Riders",
  #                    acu_type: "Regular",
  #                    acu_coverage: "Outpatient")
  #   benefit_limit = insert(:benefit_limit,
  #                          benefit: benefit,
  #                          limit_type: "Sessions",
  #                          limit_session: 1,
  #                          coverages: "ACU")
  #   package = insert(:package,
  #                    code: "Package01",
  #                    name: "Package01")
  #   insert(:package_payor_procedure, male: true, female: true,
  #          age_from: 0, age_to: 100, package: package,
  #          payor_procedure: payor_procedure)
  #   benefit_package = insert(:benefit_package,
  #                            benefit: benefit,
  #                            package: package,
  #                            age_from: 0,
  #                            age_to: 100,
  #                            male: true,
  #                            female: true
  #   )
  #   insert(:benefit_procedure,
  #                            benefit: benefit,
  #                            procedure: payor_procedure,
  #                            age_from: 0,
  #                            age_to: 100,
  #                            gender: "Male")
  #   insert(:benefit_coverage,
  #          benefit: benefit,
  #          coverage: coverage)
  #   insert(:benefit_diagnosis,
  #          benefit: benefit,
  #          diagnosis: diagnosis)
  #   product = insert(:product,
  #                    limit_amount: 100_000,
  #                    name: "Product01",
  #                    standard_product: "Yes", step: "7")
  #   insert(:product_coverage,
  #                             product: product,
  #                             coverage: coverage)
  #   product_benefit = insert(:product_benefit,
  #                             product: product,
  #                             benefit: benefit)
  #   insert(:product_benefit_limit,
  #                                   product_benefit: product_benefit,
  #                                   benefit_limit: benefit_limit,
  #                                   coverages: "ACU",
  #                                   limit_type: "Peso",
  #                                   limit_amount: 1000,
  #                                   limit_classification: "Per Transaction",
  #                                   limit_session: 1
  #                                 )

  #   insert(:product_benefit_limit,
  #           product_benefit: product_benefit,
  #           benefit_limit: benefit_limit,
  #           limit_type: "Sessions",
  #           limit_session: 1)
  #   account = insert(:account,
  #                    account_group: account_group,
  #                    start_date: Ecto.Date.cast!("2017-01-01"),
  #                    end_date: Ecto.Date.cast!("2019-02-02"),
  #                    status: "Active")
  #   account_product = insert(:account_product,
  #                            account: account,
  #                            product: product)
  #   insert(:member_product,
  #           member: member,
  #           account_product: account_product, tier: 1)
  #   facility = insert(:facility, code: "myh",
  #                     name: "MYHEALTH CLINIC - SM NORTH EDSA",
  #                     status: "Affiliated",
  #                     affiliation_date: "2017-11-10",
  #                     disaffiliation_date: "2018-11-23")
  #   package_facility = insert(:package_facility, package: package,
  #                             facility: facility, rate: 1000)

  #   params = %{
  #     "card_no" => member.card_no,
  #     "facility_code" => facility.code,
  #     "coverage_code" => coverage.code
  #   }

  #   conn =
  #     conn
  #     |> put_req_header("authorization", "bearer #{jwt}")
  #     |> get(api_authorization_path(conn, :get_acu_details, params))

  #   assert conn.status == 200
  #   assert json_response(conn, 200) ==
  #     %{
  #       "authorization_id" => conn.assigns.authorization.id,
  #       "acu_type" => benefit.acu_type,
  #       "acu_coverage" => benefit.acu_coverage,
  #       "benefit_package_id" => benefit_package.id,
  #       "benefit_code" => benefit.code,
  #       "package" => %{
  #         "id" => package.id,
  #         "code" => package.code,
  #         "name" => package.name
  #       },
  #       "package_facility_rate" => Decimal.to_string(package_facility.rate),
  #       "payor_procedure" => [
  #         %{
  #           "id" => procedure.id,
  #           "code" => procedure.code,
  #           "description" => procedure.description
  #         }
  #       ],
  #       "benefit_provider_access" => benefit.provider_access,
  #       "limit_amount" => "0",
  #       "loa_number" => nil
  #     }
  # end

  ####### disabling test for a while, due to ongoing Revamp get_acu_details frunning RegistrationLinkWeb.Endpoint with Cowboy using http://0.0.0.0:4003
  test "get_acu_details without package facility rate setup",
  %{conn: conn, jwt: jwt}
  do
    account_group = insert(:account_group, name: "ACCOUNT01", code: "ACC01")
    member = insert(:member, %{
      first_name: "Juan",
      last_name: "Dela Cruz",
      card_no: "123456789010",
      account_group: account_group,
      effectivity_date: Ecto.Date.cast!("2017-01-01"),
      expiry_date: Ecto.Date.cast!("2019-02-02"),
      birthdate: Ecto.Date.cast!("1990-01-01"),
      gender: "Male"
    })
    coverage = insert(:coverage,
                      name: "ACU",
                      description: "ACU",
                      code: "ACU",
                      type: "A",
                      status: "A",
                      plan_type: "riders")
    diagnosis = insert(:diagnosis, code: "Z00.0",
                        description: "Test Diagnosis",
                        type: "Non-Dreaded")
    procedure = insert(:procedure, code: "83498",
                       description: "HYDROXYPROGESTERONE, 17-D",
                       type: "Diagnostic")
    payor_procedure = insert(:payor_procedure, code: "LAB0503004",
                       description: "17 HYDROXY PROGESTERONE",
                       is_active: true, procedure: procedure)
    benefit = insert(:benefit, code: "B01",
                     name: "ACU Benefit",
                     category: "Riders",
                     acu_type: "Regular",
                     acu_coverage: "Outpatient")
    benefit_limit = insert(:benefit_limit,
                           benefit: benefit,
                           limit_type: "Sessions",
                           limit_session: 1,
                           coverages: "ACU")
    insert(:benefit_procedure,
                             benefit: benefit,
                             procedure: payor_procedure,
                             age_from: 0,
                             age_to: 100,
                             gender: "Male")
    package = insert(:package,
                     code: "Package01",
                     name: "Package01")
    insert(:package_payor_procedure, male: true, female: true,
           age_from: 18, age_to: 65, package: package,
           payor_procedure: payor_procedure)
    insert(:benefit_package,
           benefit: benefit,
           package: package,
           age_from: 18,
           age_to: 65,
           male: true,
           female: true
    )
    insert(:benefit_coverage,
           benefit: benefit,
           coverage: coverage)
    insert(:benefit_diagnosis,
           benefit: benefit,
           diagnosis: diagnosis)
    product = insert(:product,
                     limit_amount: 100_000,
                     name: "Product01",
                     standard_product: "Yes", step: "7")
    insert(:product_coverage,
                              product: product,
                              coverage: coverage)
    product_benefit = insert(:product_benefit,
                              product: product,
                              benefit: benefit)
    insert(:product_benefit_limit,
            product_benefit: product_benefit,
            benefit_limit: benefit_limit,
            limit_type: "Sessions",
            limit_session: 1)
    account = insert(:account,
                     account_group: account_group,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2019-02-02"),
                     status: "Active")
    account_product = insert(:account_product,
                             account: account,
                             product: product)
    insert(:member_product,
            member: member,
            account_product: account_product, tier: 1)
    facility = insert(:facility, code: "myh",
                      name: "MYHEALTH CLINIC - SM NORTH EDSA",
                      status: "Affiliated",
                      affiliation_date: "2017-11-10",
                      disaffiliation_date: "2018-11-23")

    params = %{
      "card_no" => member.card_no,
      "facility_code" => facility.code,
      "coverage_code" => coverage.code
    }

    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> get(api_authorization_path(conn, :get_acu_details, params))

    assert json_response(conn, 400) ==
      %{
        "message" => "Member is not eligible to avail ACU in this Hospital / Clinic.",
        "code" => 400
      }
  end

  ####### disabling test for a while, due to ongoing Revamp get_acu_details from List.first package to multiple package
  test "get_acu_details with availed acu and no approved datetime",
  %{conn: conn, jwt: jwt}
  do
    account_group = insert(:account_group, name: "ACCOUNT01", code: "ACC01")
    member = insert(:member, %{
      first_name: "Juan",
      last_name: "Dela Cruz",
      card_no: "123456789010",
      account_group: account_group,
      effectivity_date: Ecto.Date.cast!("2017-01-01"),
      expiry_date: Ecto.Date.cast!("2019-02-02"),
      birthdate: Ecto.Date.cast!("1990-01-01"),
      gender: "Male"
    })
    coverage = insert(:coverage,
                      name: "ACU",
                      description: "ACU",
                      code: "ACU",
                      type: "A",
                      status: "A",
                      plan_type: "riders")
    diagnosis = insert(:diagnosis, code: "Z00.0",
                        description: "Test Diagnosis",
                        type: "Non-Dreaded")
    procedure = insert(:procedure, code: "83498",
                       description: "HYDROXYPROGESTERONE, 17-D",
                       type: "Diagnostic")
    insert(:payor_procedure, code: "LAB0503004",
                       description: "17 HYDROXY PROGESTERONE",
                       is_active: true, procedure: procedure)
    benefit = insert(:benefit, code: "B01",
                     name: "ACU Benefit",
                     category: "Riders",
                     acu_type: "Regular",
                     acu_coverage: "Outpatient")
    benefit_limit = insert(:benefit_limit,
                           benefit: benefit,
                           limit_type: "Sessions",
                           limit_session: 1,
                           coverages: "ACU")
    procedure = insert(:procedure, code: "83498",
                       description: "HYDROXYPROGESTERONE, 17-D",
                       type: "Diagnostic")
    payor_procedure = insert(:payor_procedure, code: "LAB0503004",
                       description: "17 HYDROXY PROGESTERONE",
                       is_active: true, procedure: procedure)
    insert(:benefit_procedure,
                             benefit: benefit,
                             procedure: payor_procedure,
                             age_from: 0,
                             age_to: 100,
                             gender: "Male")
    package = insert(:package,
                     code: "Package01",
                     name: "Package01")
    insert(:package_payor_procedure, male: true, female: true,
           age_from: 18, age_to: 65, package: package,
           payor_procedure: payor_procedure)
    benefit_package = insert(:benefit_package,
           benefit: benefit,
           package: package,
           age_from: 18,
           age_to: 65,
           male: true,
           female: true
    )
    insert(:benefit_coverage,
           benefit: benefit,
           coverage: coverage)
    insert(:benefit_diagnosis,
           benefit: benefit,
           diagnosis: diagnosis)
    product = insert(:product,
                     limit_amount: 100_000,
                     name: "Product01",
                     standard_product: "Yes", step: "7")
    insert(:product_coverage,
                              product: product,
                              coverage: coverage)
    product_benefit = insert(:product_benefit,
                              product: product,
                              benefit: benefit)
    insert(:product_benefit_limit,
            product_benefit: product_benefit,
            benefit_limit: benefit_limit,
            limit_type: "Sessions",
            limit_session: 1)
    account = insert(:account,
                     account_group: account_group,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2019-02-02"),
                     status: "Active")
    account_product = insert(:account_product,
                             account: account,
                             product: product)
    insert(:member_product,
            member: member,
            account_product: account_product, tier: 1)
    facility = insert(:facility, code: "myh",
                      name: "MYHEALTH CLINIC - SM NORTH EDSA",
                      status: "Affiliated",
                      affiliation_date: "2017-11-10",
                      disaffiliation_date: "2018-11-23")
    insert(:package_facility, package: package,
                              facility: facility, rate: 1000)
    authorization = insert(:authorization, member: member, facility: facility,
           coverage: coverage, status: "Approved", step: 5)
    insert(:authorization_benefit_package, authorization_id: authorization.id, benefit_package_id: benefit_package.id)

    params = %{
      "card_no" => member.card_no,
      "facility_code" => facility.code,
      "coverage_code" => coverage.code
    }

    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> get(api_authorization_path(conn, :get_acu_details, params))

    assert json_response(conn, 400) ==
      %{
        "message" => "Member's ACU packages has been approved or availed",
        "code" => 400
      }
  end

  ####### disabling test for a while, due to ongoing Revamp get_acu_details from List.first package to multiple package
  test "get_acu_details with availed acu and approved datetime",
  %{conn: conn, jwt: jwt}
  do
    account_group = insert(:account_group, name: "ACCOUNT01", code: "ACC01")
    member = insert(:member, %{
      first_name: "Juan",
      last_name: "Dela Cruz",
      card_no: "123456789010",
      account_group: account_group,
      effectivity_date: Ecto.Date.cast!("2017-01-01"),
      expiry_date: Ecto.Date.cast!("2019-02-02"),
      birthdate: Ecto.Date.cast!("1990-01-01"),
      gender: "Male"
    })
    coverage = insert(:coverage,
                      name: "ACU",
                      description: "ACU",
                      code: "ACU",
                      type: "A",
                      status: "A",
                      plan_type: "riders")
    diagnosis = insert(:diagnosis, code: "Z00.0",
                        description: "Test Diagnosis",
                        type: "Non-Dreaded")
    procedure = insert(:procedure, code: "83498",
                       description: "HYDROXYPROGESTERONE, 17-D",
                       type: "Diagnostic")
    insert(:payor_procedure, code: "LAB0503004",
                       description: "17 HYDROXY PROGESTERONE",
                       is_active: true, procedure: procedure)
    benefit = insert(:benefit, code: "B01",
                     name: "ACU Benefit",
                     category: "Riders",
                     acu_type: "Regular",
                     acu_coverage: "Outpatient")
    benefit_limit = insert(:benefit_limit,
                           benefit: benefit,
                           limit_type: "Sessions",
                           limit_session: 1,
                           coverages: "ACU")
    procedure = insert(:procedure, code: "83498",
                       description: "HYDROXYPROGESTERONE, 17-D",
                       type: "Diagnostic")
    payor_procedure = insert(:payor_procedure, code: "LAB0503004",
                       description: "17 HYDROXY PROGESTERONE",
                       is_active: true, procedure: procedure)
    insert(:benefit_procedure,
                             benefit: benefit,
                             procedure: payor_procedure,
                             age_from: 0,
                             age_to: 100,
                             gender: "Male")
    package = insert(:package,
                     code: "Package01",
                     name: "Package01")
    insert(:package_payor_procedure, male: true, female: true,
           age_from: 18, age_to: 65, package: package,
           payor_procedure: payor_procedure)
    benefit_package = insert(:benefit_package,
           benefit: benefit,
           package: package,
           age_from: 18,
           age_to: 65,
           male: true,
           female: true
    )
    insert(:benefit_coverage,
           benefit: benefit,
           coverage: coverage)
    insert(:benefit_diagnosis,
           benefit: benefit,
           diagnosis: diagnosis)
    product = insert(:product,
                     limit_amount: 100_000,
                     name: "Product01",
                     standard_product: "Yes", step: "7")
    insert(:product_coverage,
                              product: product,
                              coverage: coverage)
    product_benefit = insert(:product_benefit,
                              product: product,
                              benefit: benefit)
    insert(:product_benefit_limit,
            product_benefit: product_benefit,
            benefit_limit: benefit_limit,
            limit_type: "Sessions",
            limit_session: 1)
    account = insert(:account,
                     account_group: account_group,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2019-02-02"),
                     status: "Active")
    account_product = insert(:account_product,
                             account: account,
                             product: product)
    insert(:member_product,
            member: member,
            account_product: account_product, tier: 1)
    facility = insert(:facility, code: "myh",
                      name: "MYHEALTH CLINIC - SM NORTH EDSA",
                      status: "Affiliated",
                      affiliation_date: "2017-11-10",
                      disaffiliation_date: "2018-11-23")
    insert(:package_facility, package: package,
                              facility: facility, rate: 1000)
    authorization = insert(:authorization, member: member,
                           facility: facility, coverage: coverage,
                           status: "Approved", step: 5,
                           approved_datetime: Ecto.DateTime.cast!("2018-03-08 00:00:00"))
    insert(:authorization_benefit_package, authorization_id: authorization.id, benefit_package_id: benefit_package.id)


    authorization.approved_datetime
    |> Ecto.DateTime.to_date()
    |> Ecto.Date.to_string()
    |> Innerpeace.PayorLink.Web.AuthorizationView.format_birthdate()

    params = %{
      "card_no" => member.card_no,
      "facility_code" => facility.code,
      "coverage_code" => coverage.code
    }

    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> get(api_authorization_path(conn, :get_acu_details, params))

    assert json_response(conn, 400) ==
      %{
        "message" => "Member's ACU packages has been approved or availed",
        "code" => 400
      }
  end

  test "update authorization number success", %{conn: conn, jwt: jwt} do
    authorization = insert(:authorization)
    params = %{
      loa_no: "123123"
    }

    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> put(api_authorization_path(conn, :update_loa_number, authorization.id), params)

    assert json_response(conn, 200)["message"] == "success"
  end

  test "update authorization number failed", %{conn: conn, jwt: jwt} do
    authorization = insert(:authorization)
    params = %{
    }

    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> put(api_authorization_path(conn, :update_loa_number, authorization.id), params)

    assert json_response(conn, 200)["message"] == "Invalid parameters"
  end

  # test "update authorization  otp status success", %{conn: conn, jwt: jwt} do
  #   authorization = insert(:authorization)
  #   params = %{}

  #   conn =
  #     conn
  #     |> put_req_header("authorization", "bearer #{jwt}")
  #     |> put(api_authorization_path(conn, :update_otp_status, authorization.id), params)

  #   assert json_response(conn, 200)["message"] == "success"
  # end

  test "update authorization  otp status error", %{conn: conn, jwt: jwt} do
    member = insert(:member)
    params = %{}

    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> put(api_authorization_path(conn, :update_otp_status, member.id), params)

    assert json_response(conn, 200)["message"] == "loa not found"
  end
  # End ACU

  #Request for swipe pos terminal
  test "request_loe_pos_terminal with valid parameter", %{conn: conn, jwt: jwt, member: member, facility: facility, coverage: coverage} do

    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> post(api_authorization_path(conn, :request_loe_pos_terminal, %{
        "loe_no" => "12345",
        "card_no" => member.card_no,
        "facility_code" => facility.code,
        "coverage_code" => coverage.code
      }))
    assert member.card_no == json_response(conn, 200)["member"]["card_no"]
  end

  test "request_loe_pos_terminal with invalid parameter", %{conn: conn, jwt: jwt} do

    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> post(api_authorization_path(conn, :request_loe_pos_terminal, %{
        "loe_no" => "",
        "card_no" => "",
        "facility_code" => "",
        "coverage_code" => ""
      }))
    assert json_response(conn, 404)["message"] == "Please enter a card no, Please enter facility code, Please enter coverage code, Please enter loe no"
  end

  test "request_loe_pos_terminal with parameter not found", %{conn: conn, jwt: jwt} do

    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> post(api_authorization_path(conn, :request_loe_pos_terminal, %{
        "loe_no" => "12345",
        "card_no" => "1231231231231231",
        "facility_code" => "3213123112",
        "coverage_code" => "TestData"
      }))
    assert json_response(conn, 404)["message"] == "Member not found with this card no, Coverage does not exist, Facility does not exist"
  end
end
