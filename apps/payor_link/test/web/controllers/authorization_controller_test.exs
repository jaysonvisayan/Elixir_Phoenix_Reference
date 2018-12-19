defmodule Innerpeace.PayorLink.Web.AuthorizationControllerTest do
  # import Innerpeace.PayorLink.TestHelper

  use Innerpeace.PayorLink.Web.ConnCase

  # alias Innerpeace.Db.Schemas.{
  #   User
  # }
  alias Ecto.UUID
  alias PayorLink.Guardian.Plug
  alias Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, as: AV
  alias Innerpeace.Db.Base.AuthorizationContext

  setup do
    conn = build_conn()
    user = fixture(:user_permission, %{
      keyword: "manage_authorizations",
      module: "Authorizations"
    })
    conn = authenticated(conn, user)
    account_group = insert(:account_group, name: "ACCOUNT101", code: "ACC101")
    member = insert(:member, %{
      first_name: "Daniel Eduard",
      last_name: "Andal",
      card_no: "123456789012",
      account_group: account_group,
      account_code: account_group.code,
      status: "Active"
    })
    coverage = insert(:coverage,
                      name: "OP Consult",
                      description: "OP Consult",
                      code: "OPC",
                      type: "A",
                      status: "A",
                      plan_type: "health_plans")
    diagnosis = insert(:diagnosis, code: "A05.0",
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
    insert(:product_coverage_risk_share,
            product_coverage: product_coverage)

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
                     status: "Active")
    insert(:roles, approval_limit: 10_000)
    account_product = insert(:account_product,
                             account: account,
                             product: product)

    insert(:member_product,
            member: member,
            account_product: account_product, tier: 1)
    insert(:account_product_benefit, account_product: account_product, product_benefit: product_benefit)
    facility = insert(:facility, name: "CALAMBA MEDICAL CENTER",
                      status: "Affiliated",
                      affiliation_date: "2017-11-10",
                      disaffiliation_date: "2018-11-23",
                      step: 7
    )
    insert(:product_coverage_facility, facility: facility, product_coverage: product_coverage)
    practitioner = insert(:practitioner,
                          first_name: "Daniel",
                          middle_name: "Murao",
                          last_name: "Andal",
                          effectivity_from: "2017-11-13",
                          effectivity_to: "2019-11-13")

    insert(:practitioner_facility,
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
    authorization = insert(:authorization,
                           coverage: coverage,
                           member: member,
                           facility: facility)
    {:ok, %{
      conn: conn,
      user: user,
      coverage: coverage,
      member: member,
      facility: facility,
      authorization: authorization,
      product: product,
      diagnosis: diagnosis,
      practitioner: practitioner
    }}
  end

  test "Validate Member Information redirects when data is valid", %{conn: conn} do
    date = Ecto.Date.cast!("2017-01-20")
    insert(:member, first_name: "Shane-", middle_name: "Dolot.", last_name: "Dela Rosa,", birthdate: date, suffix: "Jr")
    conn = post conn, authorization_path(conn, :validate_member_info), authorization: %{
      full_name: "Shane Dolot Dela Rosa Jr",
      birthdate: "2017-01-20"
    }

    assert redirected_to(conn) == "/authorizations/new"
  end

  test "Validate Member Information renders error when data is invalid", %{conn: conn} do
    date = Ecto.Date.cast!("2017-01-20")
    insert(:member, first_name: "Shane", middle_name: "Dolot", last_name: "Dela Rosa", birthdate: date, suffix: "Jr")
    conn = post conn, authorization_path(conn, :validate_member_info), authorization: %{
      full_name: "Shane Dolot Dela Rosa",
      birthdate: "2017-01-20"
    }

    assert conn.private[:phoenix_flash]["error"] =~ "Invalid member details."
    assert redirected_to(conn) == "/authorizations/new"
  end
  # TODO
  # test "Validate card redirects when card details is valid", %{conn: conn} do
  #   insert(:api_address, name: "PAYORLINK 1.0", address: "https://api.maxicare.com.ph/")
  #   ag = insert(:account_group)
  #   insert(:account, account_group: ag, status: "Active")
  #   insert(:member, card_no: "1168011034280092", status: "Active", account_group: ag)
  #   conn = post conn, authorization_path(conn, :validate_card), authorization: %{
  #       "card_number" => "1168011034280092",
  #       "cvv_number" =>  "209"
  #   }

  #   assert %{id: id} = redirected_params(conn)
  #   assert redirected_to(conn) == "/authorizations/#{id}/setup?step=2"
  # end

  # TODO
#   test "Validate card renders erro when card details is invalid", %{conn: conn} do
#     insert(:api_address, name: "PAYORLINK 1.0", address: "https://api.maxicare.com.ph/")
#     conn = post conn, authorization_path(conn, :validate_card), authorization: %{
#         "card_number" => "1168011034280092",
#         "cvv_number" =>  "209"
#     }

#     assert conn.private[:phoenix_flash]["error"] =~ "Card details is invalid"
#     assert redirected_to(conn) == "/authorizations/new"
#   end

  describe "Authorization Setup" do
    test "renders index page if setup url is invalid", %{conn: conn} do
      id =
        UUID.generate()

      conn =
        conn
        |> get(
          authorization_path(
            conn,
            :setup,
            id
          )
        )

      assert conn.private[:phoenix_flash]["error"] =~ "Page not found!"
      assert redirected_to(conn) == "/authorizations"
    end

    test "step2 renders select facility page if step is valid", %{conn: conn} do
      authorization =
        :authorization
        |> insert(
          step: 2
        )

      conn =
        conn
        |> get(
          authorization_path(
            conn,
            :setup,
            authorization.id,
            step: 2
          )
        )

      result =
        conn
        |> html_response(200)

      assert result =~ "Facility"
    end

    test "step2 renders index page if step is invalid", %{conn: conn} do
      id =
        UUID.generate()

      conn =
        conn
        |> get(
          authorization_path(
            conn,
            :setup,
            id,
            step: 2
          )
        )

      result =
        conn
        |> html_response(200)

      assert result =~ "Authorization"
    end

    test "setup renders search facility page with search results", %{conn: conn} do
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
        code: "Facility Code",
        name: "Makati Medical",
        step: 7,
        type: type,
        category: category
      )

      authorization =
        :authorization
        |> insert(
          step: 2
        )

      params =
        %{
          "code" => "Facility Code",
          "city" => "",
          "address" => "",
          "status" => "",
          "type" => "",
          "province" => ""
        }

      conn =
        conn
        |> get(
          authorization_path(
            conn,
            :setup,
            authorization.id
          ),
          search: params
        )

      result =
        conn
        |> html_response(200)

      assert result =~ "Makati Medical"
    end

    test "setup returns error when no search critera provided", %{conn: conn} do
      authorization =
        :authorization
        |> insert(
          step: 2
        )

      params =
        %{
          "code" => "",
          "city" => "",
          "address" => "",
          "status" => "",
          "type" => "",
          "province" => ""
        }

      conn =
        conn
        |> get(
          authorization_path(
            conn,
            :setup,
            authorization.id
          ),
          search: params
        )

      result =
        conn
        |> get_flash(:error)

      assert result == "Please enter at least one search criteria."
    end

    test "update_step2 with selected facility", %{conn: conn, authorization: authorization} do
      facility =
        :facility
        |> insert()

      params =
        %{
          "facility_id" => facility.id
        }

      conn =
        conn
        |> post(
          authorization_path(
            conn,
            :update_setup,
            authorization,
            step: 2
          ),
          authorization: params
        )

      result =
        conn
        |> redirected_to()

      flash =
        conn
        |> get_flash(:info)

      assert flash == "Successfully selected facility."
      assert result == authorization_path(conn, :setup, authorization.id, step: 3)
    end

    test "update_step2 without selected facility", %{conn: conn, authorization: authorization} do
      conn =
        conn
        |> post(
          authorization_path(
            conn,
            :update_setup,
            authorization,
            step: 2
          ),
          authorization: %{}
        )

      result =
        conn
        |> get_flash(:error)

      assert result == "Please select a facility."
    end

    test "update_step3* with valid data", %{conn: conn, authorization: authorization, coverage: coverage} do
      conn =
        conn
        |> post(
          authorization_path(
            conn,
            :update_setup,
            authorization,
            step: 3
          ),
          authorization: %{
            "coverage_id" => coverage.id
          })

      assert redirected_to(conn) == "/authorizations/#{authorization.id}/setup?step=4"

    end

    test "step3* with valid data", %{conn: conn, authorization: authorization} do
      conn = get conn, authorization_path(conn, :setup, authorization.id, step: 3)
      result = html_response(conn, 200)
      assert result =~ "Coverages"
    end

    test "step4_consult with valid data", %{conn: conn, authorization: authorization} do
      conn = get conn, authorization_path(conn, :setup, authorization.id, step: 4)
      result = html_response(conn, 200)
      assert result =~ "OP Consultation"
    end
  end

  #test "update_step4_consult with valid data",
  # %{conn: conn, authorization: authorization, diagnosis: diagnosis, practitioner: practitioner} do
  #  params =
  #  %{
  #    "consultation_type" => "initial",
  #    "chief_complaint" => "test",
  #    "practitioner_id" => practitioner.id,
  #    "diagnosis_id" => diagnosis.id
  #  }
  #  conn = post conn, authorization_path(conn, :update_setup, authorization, step: 4), authorization: params

  #  assert conn.private[:phoenix_flash]["info"] =~ "Authorization Successfully Submitted."
  #end

  #test "update_step4_consult with missing consultation_type",
  # %{conn: conn, authorization: authorization, practitioner: practitioner} do
  #  params =
  #  %{
  #    "chief_complaint" => "test",
  #    "practitioner_id" => practitioner.id,
  #    "diagnosis_id" => practitioner.id
  #  }
  #  conn = post conn, authorization_path(conn, :update_setup, authorization, step: 4), authorization: params
  #  assert conn.private[:phoenix_flash]["error"] =~ "Error in requesting OP Consult LOA."
  #end

  #test "update_step4_consult with missing chief_complaint",
  # %{conn: conn, authorization: authorization, diagnosis: diagnosis, practitioner: practitioner} do
  #  params =
  #  %{
  #    "consultation_type" => "initial",
  #    "practitioner_id" => practitioner.id,
  #    "diagnosis_id" => diagnosis.id
  #  }
  #  conn = post conn, authorization_path(conn, :update_setup, authorization, step: 4), authorization: params

  #  assert conn.private[:phoenix_flash]["error"] =~ "Error in requesting OP Consult LOA."
  #end

  #test "update_step4_consult with missing pracitioner_id",
  # %{conn: conn, authorization: authorization, diagnosis: diagnosis} do
  #  params =
  #  %{
  #    "consultation_type" => "initial",
  #    "chief_complaint" => "test",
  #    "diagnosis_id" => diagnosis.id
  #  }
  #  conn = post conn, authorization_path(conn, :update_setup, authorization, step: 4), authorization: params
  #  assert conn.private[:phoenix_flash]["error"] =~ "Error in requesting OP Consult LOA."
  #end

  #test "update_step4_consult with invalid practitioner_id",
  # %{conn: conn, authorization: authorization, diagnosis: diagnosis} do
  #  params =
  #  %{
  #    "consultation_type" => "initial",
  #    "chief_complaint" => "test",
  #    "practitioner_id" => diagnosis.id,
  #    "diagnosis_id" => diagnosis.id
  #  }
  #  conn = post conn, authorization_path(conn, :update_setup, authorization, step: 4), authorization: params
  #  assert conn.private[:phoenix_flash]["error"] =~ "Error in requesting OP Consult LOA."
  #end

  test "get_pec with valid data", %{conn: conn, authorization: authorization} do
    diagnosis = insert(:diagnosis)
    conn = post conn, authorization_path(conn, :get_pec, authorization), params: diagnosis.id

    assert conn.status == 200
  end

  test "get_consultation_fee with valid data", %{conn: conn, authorization: authorization} do
    practitioner = insert(:practitioner)
    conn = post conn, authorization_path(conn, :get_consultation_fee, authorization), params: practitioner.id

    assert conn.status == 200
  end

  #  test "compute_consultation with = valid data", %{conn: conn, authorization: authorization} do
  #    params = %{
  #      "consultation_fee" => "500",
  #      "copay" => "100",
  #      "covered" => "60",
  #      "risk_share_type" => "Copayment",
  #      "pec" => ""
  #    }
  #    conn = post conn, authorization_path(conn, :compute_consultation, authorization), params: params
  #
  #    assert json_response(conn, 200) == Poison.encode!(%{"payor": "240.0", "member": "260.0"})
  #  end

  #  test "compute_consultation with = valid data", %{conn: conn, authorization: authorization} do
  #    params = %{
  #      "consultation_fee" => "500",
  #      "copay" => "100",
  #      "covered" => "60",
  #      "risk_share_type" => "Copayment",
  #      "pec" => ""
  #    }
  #    conn = post conn, authorization_path(conn, :compute_consultation, authorization), params: params
  #
  #    assert json_response(conn, 200) == Poison.encode!(%{"payor": "240.0", "member": "260.0"})
  #  end

  test "Submit with selected member", %{conn: conn, member: member} do
    conn  = post conn, authorization_path(conn, :select_member), authorization: %{"member_id" => member.id}

    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == "/authorizations/#{id}/setup?step=2"
  end

  test "Submit without selected member", %{conn: conn} do
    conn  = post conn, authorization_path(conn, :select_member), authorization: %{"member_id" => ""}

    assert conn.private[:phoenix_flash]["error"] =~ "Please select a member."
    assert redirected_to(conn) == "/authorizations/new"
  end

  test "OTP Verify authorization", %{conn: conn} do
    authorization = insert(:authorization)
    conn  = get conn, authorization_path(conn, :auth_verified, authorization.id)

    assert conn.private[:phoenix_flash]["info"] =~ "Successfully Availed LOA"
    assert redirected_to(conn) == "/authorizations/#{authorization.id}"
  end

  test "validate_otp of original with valid data", %{conn: conn} do
    # {:ok, user} = Repo.insert(%User{username: "abbymae", password: "P@ssw0rd"})
    # conn = Plug.sign_in(build_conn(), user)
    jwt = Plug.current_token(conn)
    authorization = insert(:authorization, otp: "1234", otp_expiry: "2999-01-01T12:12:12Z")
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(authorization_path(conn, :validate_otp, authorization.id, "1234", "original"))

    assert json_response(conn, 200) == %{"message" => "Original Copy"}
  end

  test "validate_otp of duplicate with valid data", %{conn: conn} do
    # {:ok, user} = Repo.insert(%User{username: "abbymae", password: "P@ssw0rd"})
    # conn = Plug.sign_in(build_conn(), user)
    jwt = Plug.current_token(conn)
    authorization = insert(:authorization, otp: "1234", otp_expiry: "2999-01-01T12:12:12Z")
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(authorization_path(conn, :validate_otp, authorization.id, "1234", "duplicate"))

    assert json_response(conn, 200) == %{"message" => "Duplicate Copy"}
  end

  test "validate_otp with invalid data", %{conn: conn} do
    # {:ok, user} = Repo.insert(%User{username: "abbymae", password: "P@ssw0rd"})
    # conn = Plug.sign_in(build_conn(), user)
    jwt = Plug.current_token(conn)
    authorization = insert(:authorization, otp: "2345", otp_expiry: "1999-01-01T12:12:12Z")
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(authorization_path(conn, :validate_otp, authorization.id, "1234", "original"))

    assert json_response(conn, 200) == %{"message" => "Invalid OTP"}
  end

  test "validate_otp with empty otp", %{conn: conn} do
    # {:ok, user} = Repo.insert(%User{username: "abbymae", password: "P@ssw0rd"})
    # conn = Plug.sign_in(build_conn(), user)
    jwt = Plug.current_token(conn)
    authorization = insert(:authorization)
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(authorization_path(conn, :validate_otp, authorization.id, "2345", "original"))

    assert json_response(conn, 200) == %{"message" => "OTP not requested"}
  end

  test "validate_otp with expired otp", %{conn: conn} do
    # {:ok, user} = Repo.insert(%User{username: "abbymae", password: "P@ssw0rd"})
    # conn = Plug.sign_in(build_conn(), user)
    jwt = Plug.current_token(conn)
    authorization = insert(:authorization, otp: "1234", otp_expiry: "1999-01-01T12:12:12Z")
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(authorization_path(conn, :validate_otp, authorization.id, "1234", "original"))

    assert json_response(conn, 200) == %{"message" => "OTP already expired"}
  end

  test "get logs returns json array of authorization logs", %{conn: conn} do
    authorization_log = insert(:authorization_log)
    authorization_logs = AuthorizationContext.get_authorization_logs(authorization_log.authorization.id)
    # user = insert(:user, username: "test", password: "P@ssw0rd")
    # conn = Plug.sign_in(build_conn(), user)
    jwt = Plug.current_token(conn)
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(authorization_path(conn, :get_logs, authorization_log.authorization.id))
    assert json_response(conn, 200) == render_json("authorization_logs.json", logs: authorization_logs)
  end

  defp render_json(template, assigns) do
    assigns = Map.new(assigns)
    template
    |> AV.render(assigns)
    |> Poison.encode!()
    |> Poison.decode!()
  end

end
