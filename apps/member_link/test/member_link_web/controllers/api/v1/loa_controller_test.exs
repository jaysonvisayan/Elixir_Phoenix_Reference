defmodule MemberLinkWeb.Api.V1.LoaControllerTest do
  # use Innerpeace.Db.SchemaCase, async: true
  use MemberLinkWeb.ConnCase

  alias MemberLink.Guardian.Plug
  alias MemberLinkWeb.Api.V1.LoaView
  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    # Authorization,
    User
  }
  # alias Innerpeace.Db.Base.{
  #   AuthorizationContext
  # }

  setup do
    {:ok, user} = Repo.insert(%User{username: "abbymae", password: "P@ssw0rd"})
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = MemberLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)

    application = insert(:application , name: "MemberLink")
    role = insert(:role, name: "memberlink_user2", approval_limit: 10_000)

    insert(:role_application,
           role: role,
           application: application)

    insert(:user_role, user: user, role: role)


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
                     standard_product: "Yes", step: "7",
                     product_base: "Benefit-based"
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
          limit_amount: 1000,
          coverages: "OPC"
    )
    account = insert(:account,
                     account_group: account_group,
                     start_date: Ecto.Date.cast!("2012-01-01"),
                     end_date: Ecto.Date.cast!("2019-02-02"),
                     status: "Active")

    account_product = insert(:account_product,
                             account: account,
                             product: product)

    insert(:member_product,
            member: member,
            account_product: account_product, tier: 1)
    facility = insert(:facility, name: "CALAMBA MEDICAL CENTER",
                      status: "Affiliated",
                      affiliation_date: "2017-11-10",
                      disaffiliation_date: "2018-11-23")

    dropdown = insert(:dropdown, type: "VAT Status", text: "Non-Vatable", value: "Non-Vatable")

    practitioner = insert(:practitioner,
                          first_name: "Daniel",
                          middle_name: "Murao",
                          last_name: "Andal",
                          effectivity_from: "2017-11-13",
                          effectivity_to: "2019-11-13",
                          vat_status_id: dropdown.id
    )

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

    specialization = insert(:specialization, name: "Psychiatry")

    practitioner_specialization = insert(:practitioner_specialization,
                                         practitioner: practitioner,
                                         specialization: specialization)

    insert(:practitioner_facility_consultation_fee,
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

  #  test "request_op_lab/1 successfully requests loa op laboratory", %{conn: conn, jwt: jwt} do
  #   doctor = insert(:practitioner, first_name: "shane", middle_name: "reid", last_name: "dela rosa")
  #   facility = insert(:facility, name: "test facility")
  #   member = insert(:member, first_name: "shane", last_name: "dela rosa", card_no: "123567890")
  #   coverage = insert(:coverage, name: "OP Laboratory")
  #   params = %{
  #     "member_id" => member.id,
  #     "card_number" => "123567890",
  #     "doctor_id" => doctor.id,
  #     "provider_id" => facility.id,
  #     "datetime" => "09/30/2017 10:00 AM",
  #     "complaint" => "sample complaint",
  #     "availment_type" => "test type"
  #   }
  #   conn =
  #     conn
  #     |> put_req_header("authorization", "bearer #{jwt}")
  #     |> post loa_path(conn, :request_op_lab, params)
  #   loa = conn.assigns.loa
  #   assert json_response(conn, 200) == render_json("loa.json", loa: loa)

  # end

  #  test "request_op_lab/1 with invalid card number returns error message", %{conn: conn, jwt: jwt} do
  #    doctor = insert(:practitioner, first_name: "Shane", middle_name: "Reid", last_name: "dela Rosa")
  #    facility = insert(:facility, name: "Test Facility", status: "Affiliated")
  #    member = insert(:member, first_name: "Shane", last_name: "Dela Rosa", card_no: "123567890")
  #    practitioner_facility = insert(:practitioner_facility,
  #                          consultation_fee: 400,
  #                          fixed: true,
  #                          fixed_fee: 400,
  #                          coordinator_fee: 400,
  #                          facility_id: facility.id,
  #                          practitioner_id: doctor.id,
  #                          affiliation_date: Ecto.Date.utc,
  #                          disaffiliation_date: Ecto.Date.cast!({Ecto.Date.utc.year + 1,Ecto.Date.utc.month,Ecto.Date.utc.day})
  #    )
  #    params = %{
  #      "member_id" => member.id,
  #      "card_number" => "123i4567890",
  #      "doctor_id" => doctor.id,
  #      "provider_id" => facility.id,
  #      "datetime" => "09/30/2017 10:00 AM",
  #      "complaint" => "Sample Complaint",
  #      "availment_type" => "Test Type"
  #    }
  #    conn =
  #      conn
  #      |> put_req_header("authorization", "Bearer #{jwt}")
  #      |> post loa_path(conn, :request_op_lab, params)
  #    assert json_response(conn, 404) == %{"message" => "Member Not Found", "code" => 404}
  #  end
  #
  #  test "request_op_lab/1 with invalid params returns Invalid Provider", %{conn: conn, jwt: jwt} do
  #    doctor = insert(:practitioner, first_name: "Shane", middle_name: "Reid", last_name: "dela Rosa")
  #    facility = insert(:facility, name: "Test Facility")
  #    member = insert(:member, first_name: "Shane", last_name: "Dela Rosa", card_no: "123567890")
  #    params = %{
  #      "member_id" => member.id,
  #      "card_number" => "123567890",
  #      "doctor_id" => doctor.id,
  #      "datetime" => "09/30/2017 10:00 AM",
  #      "provider_id" => "123",
  #      "complaint" => "Sample Complaint",
  #      "availment_type" => "Test Type"
  #    }
  #    conn =
  #      conn
  #      |> put_req_header("authorization", "Bearer #{jwt}")
  #      |> post loa_path(conn, :request_op_lab, params)
  #    assert json_response(conn, 400) == %{"message" => "Invalid Provider", "code" => 400}
  #  end
  #
  #  test "request_op_lab/1 with invalid params returns Invalid Doctor", %{conn: conn, jwt: jwt} do
  #    doctor = insert(:practitioner, first_name: "Shane", middle_name: "Reid", last_name: "dela Rosa")
  #    facility = insert(:facility, name: "Test Facility")
  #    member = insert(:member, first_name: "Shane", last_name: "Dela Rosa", card_no: "123567890")
  #    params = %{
  #      "member_id" => member.id,
  #      "doctor_id" => "123123",
  #      "card_number" => "123567890",
  #      "datetime" => "09/30/2017 10:00 AM",
  #      "provider_id" => facility.id,
  #      "complaint" => "Sample Complaint",
  #      "availment_type" => "Test Type"
  #    }
  #    conn =
  #      conn
  #      |> put_req_header("authorization", "Bearer #{jwt}")
  #      |> post loa_path(conn, :request_op_lab, params)
  #    assert json_response(conn, 400) == %{"message" => "Invalid Doctor", "code" => 400}
  #  end
  #
  #  test "request_op_lab/1 with invalid params returns Invalid Member", %{conn: conn, jwt: jwt} do
  #    doctor = insert(:practitioner, first_name: "Shane", middle_name: "Reid", last_name: "dela Rosa")
  #    facility = insert(:facility, name: "Test Facility", status: "Affiliated")
  #    member = insert(:member, first_name: "Shane", last_name: "Dela Rosa", card_no: "123567890")
  #    practitioner_facility = insert(:practitioner_facility,
  #                          consultation_fee: 400,
  #                          fixed: true,
  #                          fixed_fee: 400,
  #                          coordinator_fee: 400,
  #                          facility_id: facility.id,
  #                          practitioner_id: doctor.id,
  #                          affiliation_date: Ecto.Date.utc,
  #                          disaffiliation_date: Ecto.Date.cast!({Ecto.Date.utc.year + 1,Ecto.Date.utc.month,Ecto.Date.utc.day})
  #    )
  #    params = %{
  #      "card_number" => "123567890",
  #      "datetime" => "09/30/2017 10:00 AM",
  #      "doctor_id" => doctor.id,
  #      "complaint" => "Sample Complaint",
  #      "availment_type" => "Test Type",
  #      "member_id" => "1231",
  #      "provider_id" => facility.id,
  #    }
  #    conn =
  #      conn
  #      |> put_req_header("authorization", "Bearer #{jwt}")
  #      |> post loa_path(conn, :request_op_lab, params)
  #    assert json_response(conn, 400) == %{"message" => "Invalid Member", "code" => 400}
  #  end
  #
  #  test "request_op_lab/1 with invalid params returns Doctor Not Found", %{conn: conn, jwt: jwt} do
  #    doctor = insert(:practitioner, first_name: "Shane", middle_name: "Reid", last_name: "dela Rosa")
  #    facility = insert(:facility, name: "Test Facility")
  #    member = insert(:member, first_name: "Shane", last_name: "Dela Rosa", card_no: "123567890")
  #    params = %{
  #      "member_id" => member.id,
  #      "card_number" => "123567890",
  #      "datetime" => "09/30/2017 10:00 AM",
  #      "doctor_id" => member.id,
  #      "complaint" => "Sample Complaint",
  #      "availment_type" => "Test Type",
  #      "provider_id" => facility.id
  #    }
  #    conn =
  #      conn
  #      |> put_req_header("authorization", "Bearer #{jwt}")
  #      |> post loa_path(conn, :request_op_lab, params)
  #    assert json_response(conn, 400) == %{"message" => "Doctor Not Found", "code" => 400}
  #  end
  #
  #  test "request_op_lab/1 with invalid params returns Provider Not Found", %{conn: conn, jwt: jwt} do
  #    doctor = insert(:practitioner, first_name: "Shane", middle_name: "Reid", last_name: "dela Rosa")
  #    facility = insert(:facility, name: "Test Facility")
  #    member = insert(:member, first_name: "Shane", last_name: "Dela Rosa", card_no: "123567890")
  #    params = %{
  #      "member_id" => member.id,
  #      "card_number" => "123567890",
  #      "datetime" => "09/30/2017 10:00 AM",
  #      "doctor_id" => doctor.id,
  #      "complaint" => "Sample Complaint",
  #      "availment_type" => "Test Type",
  #      "provider_id" => member.id
  #    }
  #    conn =
  #      conn
  #      |> put_req_header("authorization", "Bearer #{jwt}")
  #      |> post loa_path(conn, :request_op_lab, params)
  #    assert json_response(conn, 400) == %{"message" => "Provider Not Found", "code" => 400}
  #  end
  #
  #  test "request_op_lab/1 with invalid params returns Invalid DateTime Format", %{conn: conn, jwt: jwt} do
  #    doctor = insert(:practitioner, first_name: "Shane", middle_name: "Reid", last_name: "dela Rosa")
  #    facility = insert(:facility, name: "Test Facility", status: "Affiliated")
  #    member = insert(:member, first_name: "Shane", last_name: "Dela Rosa", card_no: "123567890")
  #    practitioner_facility = insert(:practitioner_facility,
  #                          consultation_fee: 400,
  #                          fixed: true,
  #                          fixed_fee: 400,
  #                          coordinator_fee: 400,
  #                          facility_id: facility.id,
  #                          practitioner_id: doctor.id,
  #                          affiliation_date: Ecto.Date.utc,
  #                          disaffiliation_date: Ecto.Date.cast!({Ecto.Date.utc.year + 1,Ecto.Date.utc.month,Ecto.Date.utc.day})
  #    )
  #    params = %{
  #      "member_id" => member.id,
  #      "card_number" => "123567890",
  #      "doctor_id" => doctor.id,
  #      "complaint" => "Sample Complaint",
  #      "availment_type" => "Test Type",
  #      "datetime" => "oajwdp123",
  #      "provider_id" => facility.id
  #    }
  #    conn =
  #      conn
  #      |> put_req_header("authorization", "Bearer #{jwt}")
  #      |> post loa_path(conn, :request_op_lab, params)
  #    assert json_response(conn, 400) == %{"message" => "Invalid DateTime Format", "code" => 400}
  #  end

  # test "request_op_lab/1 with invalid params returns error message", %{conn: conn, jwt: jwt} do
  #   doctor = insert(:practitioner, first_name: "Shane", middle_name: "Reid", last_name: "dela Rosa")
  #   facility = insert(:facility, name: "Test Facility")
  #   member = insert(:member, first_name: "Shane", last_name: "Dela Rosa", card_no: "123567890")
  #   coverage = insert(:coverage, name: "OP Laboratory")
  #   params = %{
  #     "member_id" => member.id,
  #     "card_number" => "123567890",
  #     "doctor_id" => doctor.id,
  #     "provider_id" => facility.id,
  #     "datetime" => "09/30/2017 10:00 AM",
  #     "complaint" => "",
  #   }
  #   conn =
  #     conn
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> post loa_path(conn, :request_op_lab, params)
  #   changeset = conn.assigns.changeset
  #   assert json_response(conn, 400) == render_error_json("changeset_error.json", changeset: changeset)
  # end

  defp render_json(template, assigns) do
    assigns = Map.new(assigns)

    view = LoaView.render(template, assigns)
    view
    |> Poison.encode!
    |> Poison.decode!
  end

  test "request_op_consult/1 successfully requests loa op consult", %{conn: conn, jwt: jwt,
    diagnosis: diagnosis, member: member,
    facility: facility, diagnosis: diagnosis, product: product,
    product_coverage: product_coverage,
    practitioner_specialization: practitioner_specialization
  } do
    insert(:product_coverage_risk_share,
           product_coverage: product_coverage,
           af_type: "Copayment",
           af_covered_amount: 80,
           naf_reimbursable: "No",
           naf_type: "Copayment",
           naf_covered_amount: 80,
           af_value_amount: 100,
           naf_value_amount: 100)
    exclusion = insert(:exclusion, coverage: "Pre-existing Condition", code: "test", name: "test")
      insert(:exclusion_duration, exclusion: exclusion, disease_type: "Dreaded",
             duration: 12, percentage: 50)
    insert(:exclusion_disease, exclusion: exclusion, disease: diagnosis)
      insert(:product_exclusion, product: product, exclusion: exclusion)

      params = %{
        "member_id" => member.id,
        "card_number" => "1234567890123456",
        "practitioner_specialization_id" => practitioner_specialization.id,
        "provider_id" => facility.id,
        "datetime" => "09/30/2017 10:00 AM",
        "chief_complaint" => "sample complaint"
    }
    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> post(loa_path(conn, :request_op_consult, params))
    loa = conn.assigns.loa
    assert json_response(conn, 200) == render_json("loa.json", loa: loa)
  end

  test "request_op_consult/1 with invalid card number returns error message", %{conn: conn, jwt: jwt,
    diagnosis: diagnosis,
    member: member,
    facility: facility,
    diagnosis: diagnosis,
    practitioner_specialization: practitioner_specialization
  } do

    params = %{
        "member_id" => member.id,
        "card_number" => "1234567890123457",
        "practitioner_specialization_id" => practitioner_specialization.id,
        "provider_id" => facility.id,
        "datetime" => "09/30/2017 10:00 AM",
        "chief_complaint" => "sample complaint"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(loa_path(conn, :request_op_consult, params))
    assert json_response(conn, 400) == %{"message" => "Card number not affiliated with member", "code" => 400}
  end

  test "request_op_consult/1 with invalid params returns Invalid Provider", %{conn: conn, jwt: jwt,
    practitioner_specialization: practitioner_specialization,
    member: member} do

    params = %{
        "member_id" => member.id,
        "card_number" => "1234567890123457",
        "practitioner_specialization_id" => practitioner_specialization.id,
        "provider_id" => "123123123123123",
        "datetime" => "09/30/2017 10:00 AM",
        "chief_complaint" => "sample complaint"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(loa_path(conn, :request_op_consult, params))
    assert json_response(conn, 400) == %{"message" => "Invalid Facility ID", "code" => 400}
  end

  test "request_op_consult/1 with invalid params returns Invalid Practitioner Specialization", %{conn: conn, jwt: jwt,
    member: member, facility: facility} do

    params = %{
        "member_id" => member.id,
        "card_number" => "1234567890123457",
        "practitioner_specialization_id" => "123123123123",
        "provider_id" => facility.id,
        "datetime" => "09/30/2017 10:00 AM",
        "chief_complaint" => "sample complaint"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(loa_path(conn, :request_op_consult, params))
    assert json_response(conn, 400) == %{"message" => "Invalid Practitioner Specialization ID", "code" => 400}
  end

  test "request_op_consult/1 with invalid params returns Invalid Member", %{conn: conn, jwt: jwt,
    practitioner_specialization: practitioner_specialization,
    facility: facility} do

    params = %{
        "member_id" => "123123123123123",
        "card_number" => "1234567890123456",
        "practitioner_specialization_id" => practitioner_specialization.id,
        "provider_id" => facility.id,
        "datetime" => "09/30/2017 10:00 AM",
        "chief_complaint" => "sample complaint"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(loa_path(conn, :request_op_consult, params))
    assert json_response(conn, 400) == %{"message" => "Invalid Member ID", "code" => 400}
  end

  # test "request_op_consult/1 with invalid params returns Doctor Not Found", %{conn: conn, jwt: jwt,
  #   member: member,
  #   facility: facility} do
  #   params = %{
  #     "member_id" => member.id,
  #     "card_number" => "123567890",
  #     "datetime" => "09/30/2017 10:00 AM",
  #     "doctor_id" => member.id,
  #     "complaint" => "",
  #     "provider_id" => facility.id,
  #   }
  #   conn =
  #     conn
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> post(loa_path(conn, :request_op_consult, params))
  #   assert json_response(conn, 400) == %{"message" => "Doctor Not Found", "code" => 400}
  # end

  # test "request_op_consult/1 with invalid params returns Provider Not Found", %{conn: conn, jwt: jwt,
  #   practitioner: practitioner, member: member} do
  #   params = %{
  #     "member_id" => member.id,
  #     "card_number" => "123567890",
  #     "datetime" => "09/30/2017 10:00 AM",
  #     "doctor_id" => practitioner.id,
  #     "complaint" => "",
  #     "provider_id" => member.id,
  #   }
  #   conn =
  #     conn
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> post(loa_path(conn, :request_op_consult, params))
  #   assert json_response(conn, 400) == %{"message" => "Provider Not Found", "code" => 400}
  # end

  test "request_op_consult/1 with invalid params returns Invalid DateTime Format", %{conn: conn, jwt: jwt,
    diagnosis: diagnosis,
    member: member,
    facility: facility,
    diagnosis: diagnosis,
    practitioner_specialization: practitioner_specialization
  } do

    params = %{
        "member_id" => member.id,
        "card_number" => "1234567890123456",
        "practitioner_specialization_id" => practitioner_specialization.id,
        "provider_id" => facility.id,
        "datetime" => "123123",
        "chief_complaint" => "sample complaint"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(loa_path(conn, :request_op_consult, params))
    assert json_response(conn, 400) == %{"message" => "Invalid DateTime Format", "code" => 400}
  end

  # test "request_op_consult/1 with invalid params returns error message", %{conn: conn, jwt: jwt,
  #   practitioner: practitioner, member: member, facility: facility} do
  #   params = %{
  #     "member_id" => member.id,
  #     "card_number" => "123456789012",
  #     "doctor_id" => practitioner.id,
  #     "provider_id" => facility.id,
  #     "datetime" => "09/30/2017 10:00 AM",
  #     "complaint" => "",
  #   }
  #   conn =
  #     conn
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> post(loa_path(conn, :request_op_consult, params))
  #   changeset = conn.assigns.changeset
  #   assert json_response(conn, 400) == render_error_json("changeset_error.json", changeset: changeset)
  # end

  test "request_op_consult/1 with invalid params returns Practitioner Specialization Not Found", %{conn: conn, jwt: jwt,
    diagnosis: diagnosis,
    member: member,
    facility: facility} do
    params = %{
      "member_id" => member.id,
      "card_number" => "1234567890123456",
      "datetime" => "09/30/2017 10:00 AM",
      "diagnosis_id" => diagnosis.id,
      "chief_complaint" => "asdasd",
      "practitioner_specialization_id" => facility.id,
      "provider_id" => facility.id
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(loa_path(conn, :request_op_consult, params))
    assert json_response(conn, 400) == %{"message" => "Practitioner Specialization does not exist", "code" => 400}
  end

  test "request_op_consult/1 with invalid params returns Provider Not Found", %{conn: conn, jwt: jwt,
    diagnosis: diagnosis,
    member: member,
    practitioner_specialization: practitioner_specialization
  } do

    params = %{
      "member_id" => member.id,
      "card_number" => "1234567890123456",
      "datetime" => "09/30/2017 10:00 AM",
      "diagnosis_id" => diagnosis.id,
      "chief_complaint" => "asdasd",
      "practitioner_specialization_id" => practitioner_specialization.id,
      "provider_id" => practitioner_specialization.id
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(loa_path(conn, :request_op_consult, params))
    assert json_response(conn, 400) == %{"message" => "Facility does not exist.", "code" => 400}
  end

  # test "request_op_consult/1 with invalid doctor provider affiliation return invalid affilication", %{conn: conn, jwt: jwt} do
  #   doctor = insert(:practitioner, first_name: "Shane", middle_name: "Reid", last_name: "dela Rosa", status: "Affiliated")
  #   specialization = insert(:specialization, name: "Neurology")
  #   practitioner_specialization = insert(:practitioner_specialization, practitioner: doctor, specialization: specialization)
  #   facility = insert(:facility, name: "Test Facility", status: "Affiliated")
  #   member = insert(:member, first_name: "Shane", last_name: "Dela Rosa", card_no: "123567890")
  #   params = %{
  #     "member_id" => member.id,
  #     "card_number" => "1234567890123456",
  #     "practitioner_specialization_id" => practitioner_specialization.id,
  #     "provider_id" => facility.id,
  #     "datetime" => "09/30/2017 10:00 AM",
  #     "chief_complaint" => "ASD",
  #   }
  #   conn =
  #     conn
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> post(loa_path(conn, :request_op_consult, params))
  #   assert json_response(conn, 400) == %{"message" => "Invalid Doctor Provider Affiliation", "code" => 400}
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
      "chief_complaint" => "asdasd",
      "provider_id" => facility.id
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(loa_path(conn, :request_op_consult, params))
    assert json_response(conn, 400) == %{"message" => "There's no Product in Member", "code" => 400}
  end


  test "get_loa by current user returns all loa" do
    loa = insert(:authorization)
    {:ok, user} = Repo.insert(%User{username: "abbymae1", password: "P@ssw0rd", member_id: loa.member_id})
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = MemberLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)
    insert(:practitioner, first_name: "shane", middle_name: "reid", last_name: "dela rosa")
    insert(:facility, name: "test facility")

    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> get(loa_path(conn, :get_loa))
    loa = conn.assigns.loa
    assert json_response(conn, 200) == render_json("list_loa.json", loa: loa)
  end

  test "get_loa by current user returns Loa not found" do
    member = insert(:member, first_name: "Shane", last_name: "Dela Rosa", card_no: "123567890")
    {:ok, user} = Repo.insert(%User{username: "abbymae1", password: "P@ssw0rd", member_id: member.id})
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = MemberLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)
    insert(:practitioner, first_name: "shane", middle_name: "reid", last_name: "dela rosa")
    insert(:facility, name: "test facility")

    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> get(loa_path(conn, :get_loa))
    assert json_response(conn, 404) == %{"message" => "No Loas Found", "code" => 404}
  end

end
