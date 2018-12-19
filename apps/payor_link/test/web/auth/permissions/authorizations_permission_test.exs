defmodule Innerpeace.PayorLink.Web.Permission.AuthorizationTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
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

    specialization = insert(:specialization, name: "Neurology")

    ps = insert(:practitioner_specialization,
           specialization: specialization,
           practitioner: practitioner,
           type: "Primary")


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

    insert(:authorization_diagnosis,
           authorization: authorization,
           diagnosis: diagnosis,
           payor_pay: 1200,
           payor_portion: 100,
           payor_vat_amount: 100,
           member_pay: 100,
           member_portion: 10,
           member_vat_amount: 10,
           special_approval_amount: 1,
           special_approval_portion: 1,
           special_approval_vat_amount: 1,
           vat_amount: 1,
           total_amount: 1,
           pre_existing_amount: 1
    )

    insert(:authorization_practitioner_specialization,
           authorization: authorization,
           practitioner_specialization: ps)

    {:ok, %{
      conn: conn,
      coverage: coverage,
      member: member,
      facility: facility,
      authorization: authorization,
      product: product,
      diagnosis: diagnosis,
      practitioner: practitioner
    }}
  end

  describe "Authorization Permission /authorizations" do
    test "with manage_authorizations should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_authorizations",
        module: "Authorizations"
      })

      conn = get authenticated(conn, u), authorization_path(conn, :index)
      assert html_response(conn, 200) =~ "LOA"
    end

    test "with access_accounts should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_authorizations",
        module: "Authorizations"
      })

      conn = get authenticated(conn, u), authorization_path(conn, :index)

      assert html_response(conn, 200) =~ "LOA"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), authorization_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end

  describe "Authorization Permission /authorizations/:id" do
    test "with manage_authorizations should have access to show", %{conn: conn, authorization: authorization} do
      u = fixture(:user_permission, %{
        keyword: "manage_authorizations",
        module: "Authorizations"
      })

      conn = get authenticated(conn, u), authorization_path(conn, :show, authorization.id)
      assert html_response(conn, 200) =~ "LOA"
    end

    test "with access_authorizations should have access to show", %{conn: conn, authorization: authorization} do
      u = fixture(:user_permission, %{
        keyword: "manage_authorizations",
        module: "Authorizations"
      })

      conn = get authenticated(conn, u), authorization_path(conn, :show, authorization.id)

      assert html_response(conn, 200) =~ "LOA"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), authorization_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
