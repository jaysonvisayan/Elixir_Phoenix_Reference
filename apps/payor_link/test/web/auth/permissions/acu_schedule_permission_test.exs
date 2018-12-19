defmodule Innerpeace.PayorLink.Web.Permission.AcuScheduleTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
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

    account_group_address = insert(:account_group_address,
                                   line_1: "Sample",
                                   line_2: "Sample2",
                                   city: "Manila",
                                   province: "Leyte",
                                   country: "Philippines",
                                   region: "NCR",
                                   postal_code: "0000",
                                   account_group: account_group)
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
                     acu_coverage: "Outpatient",
                     provider_access: "Hospital/Clinic and Mobile"
    )
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
    insert(:benefit_package,
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
                     standard_product: "Yes",
                     step: "7",
                     product_base: "Benefit-based",
                     loa_facilitated: true,
                     code: "PRD-123456"
    )
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
    insert(:account_product_benefit,
           account_product: account_product,
           product_benefit: product_benefit
    )
    insert(:member_product,
            member: member,
            account_product: account_product, tier: 1)
    insert(:dropdown, type: "Facility Category", text: "Primary + Mobile")
    facility = insert(:facility, code: "myh",
                      name: "MYHEALTH CLINIC - SM NORTH EDSA",
                      status: "Affiliated",
                      affiliation_date: "2017-11-10",
                      disaffiliation_date: "2018-11-23"
    )
    insert(:authorization, member: member,
                           facility: facility, coverage: coverage,
                           status: "Draft", step: 3)
    acu_schedules = insert(:acu_schedule,
                           account_group: account_group,
                           facility: facility,
                           status: "Active",
                           batch_no: 123,
                           date_from: ~D[2000-01-01],
                           date_to: ~D[2000-01-01],
                           time_from: Time.utc_now(),
                           time_to: Time.utc_now(),
                           no_of_members: 5,
                           no_of_guaranteed: 5

    )
    acu_schedules_draft = insert(:acu_schedule,
        account_group: account_group,
        facility: facility,
        status: "Draft"
    )

    acu_schedules_draft2 = insert(:acu_schedule,
        account_group: account_group,
        facility: facility,
        status: "Draft2"
    )

    acu_sched_member = insert(:acu_schedule_member, acu_schedule: acu_schedules, member: member)
    {:ok, %{conn: conn,
      account_product: account_product,
      product: product,
      account_group: account_group,
      account: account,
      acu_schedules: acu_schedules,
      acu_schedules_draft: acu_schedules_draft,
      acu_sched_member: acu_sched_member,
      member: member,
      acu_schedules_draft2: acu_schedules_draft2,
      account_group_address: account_group_address}}
  end

  describe "ACU Schedule Permission /acu_schedules" do
    test "with manage_acu_schedules should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_acu_schedules",
        module: "Acu_Schedules"
      })

      conn = get authenticated(conn, u), acu_schedule_path(conn, :index)
      assert html_response(conn, 200) =~ "acu"
    end

    test "with access_acu_schedules should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_acu_schedules",
        module: "Acu_Schedules"
      })

      conn = get authenticated(conn, u), acu_schedule_path(conn, :index)

      assert html_response(conn, 200) =~ "acu"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), acu_schedule_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end

  describe "ACU Schedule Permission /acu_schedules/:id" do
    test "with manage_acu_schedules should have access to show", %{conn: conn, acu_schedules: acu_schedules} do
      u = fixture(:user_permission, %{
        keyword: "manage_acu_schedules",
        module: "Acu_Schedules"
      })

      conn = get authenticated(conn, u), acu_schedule_path(conn, :show, acu_schedules.id)
      assert html_response(conn, 200) =~ "acu"

    end

    test "with access_acu_schedules should have access to show", %{conn: conn, acu_schedules: acu_schedules} do
      u = fixture(:user_permission, %{
        keyword: "access_acu_schedules",
        module: "Acu_Schedules"
      })

      conn = get authenticated(conn, u), acu_schedule_path(conn, :show, acu_schedules.id)
      assert html_response(conn, 200) =~ "acu"

    end
  end

  describe "ACU Schedule Permission /acu_schedules/:id/edit" do
    test "with manage_acu_schedules should have access to edit", %{conn: conn, acu_schedules: acu_schedules} do
      u = fixture(:user_permission, %{
        keyword: "manage_acu_schedules",
        module: "Acu_Schedules"
      })

      conn = get authenticated(conn, u), acu_schedule_path(conn, :edit, acu_schedules.id)
      assert redirected_to(conn, 302) == "/acu_schedules/#{acu_schedules.id}/packages"

    end

    # test "with access_acu_schedules should not have access to edit", %{conn: conn, acu_schedules: acu_schedules} do
    #   u = fixture(:user_permission, %{
    #     keyword: "access_acu_schedules",
    #     module: "Acu_Schedules"
    #   })

    #   conn = get authenticated(conn, u), acu_schedule_path(conn, :edit, acu_schedules.id)
    #   assert redirected_to(conn, 302) == "/"

    # end
  end
end
