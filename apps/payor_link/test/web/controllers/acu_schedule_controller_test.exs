defmodule Innerpeace.PayorLink.Web.AcuScheduleControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper

  setup do
    conn = build_conn()
    user = fixture(:user_permission, %{keyword: "manage_acu_schedules", module: "Acu_Schedules"})
    conn = authenticated(conn, user)
    # user = insert(:user, is_admin: true)
    # conn = sign_in(conn, user)
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
                           no_of_guaranteed: 5,
                           member_type: "Principal and Dependent"

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
      user: user,
      account_group: account_group,
      account: account,
      acu_schedules: acu_schedules,
      acu_schedules_draft: acu_schedules_draft,
      acu_sched_member: acu_sched_member,
      member: member,
      acu_schedules_draft2: acu_schedules_draft2,
      account_group_address: account_group_address}}
  end

  test "index/2, lists all entries on index", %{conn: conn} do
    conn = get conn, acu_schedule_path(conn, :index)
    assert html_response(conn, 200) =~ "ACU Scheduling"
  end

  test "show/2, show acu schedule with valid parameters", %{conn: conn, acu_schedules: acu_schedules} do
    # user = insert(:user, username: "test", password: "P@ssw0rd")
    # conn = Plug.sign_in(build_conn(), user)
    conn = get conn, acu_schedule_path(conn, :show, acu_schedules.id)
    assert html_response(conn, 200) =~ "Show"
  end

  test "show/2, show acu schedule with invalid parameters", %{conn: conn} do
    params = %{id: Ecto.UUID.generate()}
    conn = get conn, acu_schedule_path(conn, :show, params.id)
   assert get_flash(conn, :error) == "ACU Schedule not Found"
  end

  test "new/1 renders add acu schedule page", %{conn: conn} do
    conn = get conn, acu_schedule_path(conn, :new)
    assert html_response(conn, 200) =~ "Add ACU Schedule"
  end

  test "delete_acu_schedule/2 delete an acu schedule", %{conn: conn, acu_schedules: acu_schedules} do
    conn = get conn, acu_schedule_path(conn, :delete_acu_schedule, acu_schedules.id)
   assert get_flash(conn, :info) == "ACU Schedule successfully deleted"
  end

  test "edit/2, renders edit acu schedule page with status draft", %{conn: conn, acu_schedules_draft: acu_schedules_draft} do
    conn = get conn, acu_schedule_path(conn, :edit, acu_schedules_draft.id)
     assert html_response(conn,200) =~ "Add ACU"
  end

  test "edit/2, renders edit acu schedule page with status completed", %{conn: conn, acu_schedules: acu_schedules} do
    conn = get conn, acu_schedule_path(conn, :edit, acu_schedules.id)
     assert redirected_to(conn) == "/acu_schedules/#{acu_schedules.id}/packages"
  end

  test "update_asm_status/2, updates asm status with valid parameters",%{conn: conn, acu_sched_member: acu_sched_member} do
    asm = %{
      "asm" => "Glen",
      "asm_id" => acu_sched_member.id,
      "as_id" => acu_sched_member.acu_schedule_id
    }
    params = %{"asm": asm}
    conn = put conn, acu_schedule_path(conn, :update_asm_status, params)
    assert redirected_to(conn) == "/acu_schedules/#{acu_sched_member.acu_schedule_id}/edit"
  end

  test "update_asm_status/2, updates asm status with invalid parameters", %{conn: conn, acu_sched_member: acu_sched_member} do
    asm = %{
      "asm_id": acu_sched_member.id,
      "as_id": ""
    }
    params = %{"asm": asm}
    conn = put conn, acu_schedule_path(conn, :update_asm_status, params)
    assert get_flash(conn, :error) == nil
  end

  test "update_multiple_asm_status/2, updates multiple asm status with valid parameters", %{conn: conn, acu_sched_member: acu_sched_member, acu_schedules: acu_schedules, member: member} do
    acu_sched_member2 = insert(:acu_schedule_member, acu_schedule: acu_schedules, member: member)
    acu_sched_member3 = insert(:acu_schedule_member, acu_schedule: acu_schedules, member: member)

    asm_ids = [acu_sched_member.id, acu_sched_member2.id, acu_sched_member3.id]
    asm = %{
      "asm_ids" => Enum.join(asm_ids, ","),
      "as_id" => acu_sched_member.acu_schedule_id
    }
    params = %{"asm" => asm}
    conn = put conn, acu_schedule_path(conn, :update_multiple_asm_status, params)
    assert redirected_to(conn) == "/acu_schedules/#{acu_sched_member.acu_schedule_id}/edit"
  end

  test "update_multiple_asm_status/2, updates multiple asm status with invalid parameters", %{conn: conn, acu_sched_member: acu_sched_member} do

    asm = %{
      "asm_ids" => "",
      "as_id" => acu_sched_member.acu_schedule_id
    }
    params = %{"asm" => asm}
    conn = put conn, acu_schedule_path(conn, :update_multiple_asm_status, params)
    assert redirected_to(conn) == "/acu_schedules/#{acu_sched_member.acu_schedule_id}/edit"
    assert get_flash(conn, :error) == "Please select at least one member."
  end

  # test "submit_acu_schedule_member/2, submit acu schedule member with valid parameters", %{conn: conn, acu_sched_member: acu_sched_member, acu_schedules: acu_schedules, member: member} do
  #   acu_sched = %{"is_equal" => "true"}
  #   params = %{
  #     "acu_schedule" => acu_sched,
  #     "id" => acu_sched_member.acu_schedule.id
  #   }
  #   conn = post conn, acu_schedule_path(conn, :submit_acu_schedule_member, acu_schedules.id), params
  #   assert redirected_to(conn) == "/acu_schedules/#{acu_sched_member.acu_schedule_id}/packages"
  # end

 # test "submit_acu_schedule_member/2, submit acu schedule member with invalid parameters", %{conn: conn, acu_sched_member: acu_sched_member, acu_schedules: acu_schedules, member: member} do
 #    acu_sched = %{"is_equal" => "false"}
 #    params = %{
 #      "acu_schedule" => acu_sched,
 #      "id" => acu_sched_member.acu_schedule.id
 #    }
 #    conn = post conn, acu_schedule_path(conn, :submit_acu_schedule_member, acu_schedules.id), params
 #    assert redirected_to(conn) == "/acu_schedules/#{acu_sched_member.acu_schedule_id}/edit"
 #    assert get_flash(conn, :error) == "No. of guaranteed heads must be equal to the no. of members displayed in the table."
 # end

 test "render_acu_schedule_packages/2, renders acu schedule packages status draft", %{conn: conn, acu_schedules_draft2: acu_schedule_draft2} do
   conn = get conn, acu_schedule_path(conn, :render_acu_schedule_packages, acu_schedule_draft2.id)
   assert html_response(conn, 200) =~ "package"
 end

 test "render_acu_schedule_packages/2, renders acu schedule packages", %{conn: conn, acu_schedules: acu_schedules} do
   conn = get conn, acu_schedule_path(conn, :render_acu_schedule_packages, acu_schedules.id)
   assert redirected_to(conn) == "/acu_schedules/#{acu_schedules.id}"
 end

 test "get_acu_product/2", %{conn: conn, product: product, account: account} do
   result = [product.code]
   conn = get conn, acu_schedule_path(conn, :get_acu_product, account.account_group.code)
   assert json_response(conn, 200) == Poison.encode!(result)
 end

 test "acu_schedule_export/2", %{conn: conn, acu_schedules: acu_schedules} do
   acu_data = %{"id": acu_schedules.id, "datetime": "May 10, 2018 04:58 PM", "acu_schedule": acu_schedules}
   params = Poison.encode!(acu_data)
   param = %{"acu_data" => params}
   conn = get conn, acu_schedule_path(conn, :acu_schedule_export, params)
   format = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
   assert response(conn, 200)
 end

 # test "create_acu_schedule_loa", %{conn: conn, acu_schedules: acu_schedules} do
 #   conn = post conn, acu_schedule_path(conn, :create_acu_schedule_loa, acu_schedules.id)
 # end
 # test "", %{conn: conn, } do
 # end
end
