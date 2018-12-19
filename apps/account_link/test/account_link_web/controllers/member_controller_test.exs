defmodule AccountLinkWeb.MemberControllerTest do
  use AccountLinkWeb.ConnCase
  use Innerpeace.Db.SchemaCase, async: true

  alias AccountLink.Guardian.Plug
  alias Innerpeace.Db.Schemas.{
    User,
    AccountGroup,
    UserAccount,
    PaymentAccount
  }
  alias Innerpeace.Db.Base.MemberContext

  setup do
    {:ok, account_group} = Repo.insert(%AccountGroup{code: "12345"})
    _account = insert(:account,
                     account_group: account_group,
                     start_date: Ecto.Date.cast!("2018-01-01"),
                     end_date: Ecto.Date.cast!("2020-01-01"),
                     status: "Active")
    {:ok, user} = Repo.insert(%User{
      username: "masteradmin",
      password: "P@ssw0rd"
    })
    Repo.insert(%UserAccount{
      user_id: user.id,
      account_group_id: account_group.id
    })
    conn = AccountLinkWeb.Auth.login(build_conn(), user)
    jwt = Plug.current_token(conn)
    member = insert(:member,
                    account_group: account_group,
                    account_code: account_group.code,
                    first_name: "Test01",
                    last_name: "Test01",
                    expiry_date: Ecto.Date.cast!("2020-01-01"),
                    effectivity_date: Ecto.Date.cast!("2018-01-01"))
    Repo.insert(%PaymentAccount{account_group: account_group, funding_arrangement: "ASO"})

    {:ok, %{
      member: member,
      jwt: jwt,
      conn: conn,
      user: user,
      account_group: account_group
    }}
  end

  test "render member index", %{conn: conn} do
    conn = get(conn, member_path(conn, :index, @locale))
    assert html_response(conn, 200) =~ "Member"
  end

  test "render member show", %{conn: conn, member: member} do
    conn = get(conn, member_path(conn, :show, @locale, member.id))
    assert html_response(conn, 200) =~ "Member"
  end

  test "add member product on show page", %{conn: conn, member: member} do
    account_product = insert(:account_product)
    params = %{
      "account_product_ids_main" => "#{account_product.id}"
    }
    conn = post(conn, member_path(conn, :add_member_product, @locale,
                                  member, member: params))
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == member_path(conn, :show, @locale, id)
  end

  test "deleting_member_product, deleting member product record", %{conn: conn} do
    insert(:coverage, name: "ACU")
    member_product = insert(:member_product, tier: 1)

    conn = delete(conn, member_path(conn, :delete_member_product, @locale,
                                    member_product.member_id, member_product.id))
    assert json_response(conn, 200) == Poison.encode!(%{
      valid: true
    })
  end

  test "render member new", %{conn: conn} do
    conn = get(conn, member_path(conn, :new, @locale))
    assert html_response(conn, 200) =~ "Enroll New Member"
  end

  test "create_general with valid params", %{conn: conn, account_group: account_group} do
    params = %{
      account_group_id: account_group.id,
      account_code: account_group.code,
      first_name: "Test01",
      last_name: "Test01",
      birthdate: "1990-01-01",
      gender: "Female",
      civil_status: "Single",
      type: "Principal",
      effectivity_date: "2017-10-01",
      expiry_date: "2018-10-01",
      employee_no: "Test01",
      is_regular: true,
      philhealth_type: "Required",
      philhealth: "123456789012",
      for_card_issuance: true,
      skipping_hierarchy: [""]
    }

    conn = post(conn, member_path(conn, :create_general, @locale), member: params)

    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == member_path(conn, :setup, @locale, id, step: "2")
  end

  test "create_general with invalid params", %{conn: conn, account_group: account_group} do
    params = %{
      account_group_id: account_group.id,
      account_code: account_group.code
    }

    conn = post(conn, member_path(conn, :create_general, @locale), member: params)

    assert html_response(conn, 200) =~ "Enroll New Member"
  end

  test "step1 with valid member", %{conn: conn, member: member} do
    conn = get(conn, member_path(conn, :setup, @locale, member, step: "1"))

    assert html_response(conn, 200) =~ member.first_name
  end

  test "step1_update with valid params", %{conn: conn, account_group: account_group, member: member} do
    params = %{
      account_group_id: account_group.id,
      account_code: account_group.code,
      first_name: "NewTest01",
      last_name: "Test01",
      birthdate: "1990-01-01",
      gender: "Female",
      civil_status: "Single",
      type: "Principal",
      effectivity_date: "2017-10-01",
      expiry_date: "2018-10-01",
      employee_no: "Test01",
      is_regular: true,
      philhealth_type: "Required",
      philhealth: "123456789012",
      for_card_issuance: false,
      skipping_hierarchy: [""]
    }

    conn = post(conn, member_path(conn, :update_setup, @locale, member,
                                  step: "1", member: params))

    assert %{id: id} = redirected_params(conn)

    if member.step == 5 do
      assert redirected_to(conn) == member_path(conn, :show, @locale, id)
    else
      assert redirected_to(conn) == member_path(conn, :setup, @locale, id, step: "2")
    end
  end

  test "step1_update with invalid params", %{conn: conn, account_group: account_group, member: member} do
    params = %{
      account_group_id: account_group.id,
      account_code: account_group.code
    }

    conn = post(conn, member_path(conn, :update_setup, @locale, member,
                                  step: "1", member: params))

    assert html_response(conn, 200) =~ member.first_name
  end

  test "step2 with valid member", %{conn: conn, member: member} do
    conn = get(conn, member_path(conn, :setup, @locale, member, step: "2"))

    assert html_response(conn, 200) =~ "Products"
  end

  test "step2_update with valid params", %{conn: conn, member: member} do
    account_product = insert(:account_product)
    params = %{
      "account_product_ids_main" => "#{account_product.id}"
    }

    conn = post(conn, member_path(conn, :update_setup, @locale, member,
                                  step: "2", member: params))

    assert %{id: id} = redirected_params(conn)

    if member.step == 5 do
      assert redirected_to(conn) == member_path(conn, :show, @locale, id)
    else
      assert redirected_to(conn) == member_path(conn, :setup, @locale, id, step: "2")
    end
  end

  test "step2_update with invalid params", %{conn: conn, member: member} do
    params = %{
      "account_product_ids_main" => ""
    }

    conn = post(conn, member_path(conn, :update_setup, @locale, member,
                                  step: "2", member: params))

    assert html_response(conn, 200) =~ "Products"
  end

  test "step3 with valid member", %{conn: conn, member: member} do
    conn = get(conn, member_path(conn, :setup, @locale, member, step: "3"))

    assert html_response(conn, 200) =~ "Contact"
  end

  test "step3_update with valid params", %{conn: conn, member: member} do
    params = %{
      email: "Test01@email.com",
      mobile: "09101001245"
    }

    conn = post(conn, member_path(conn, :update_setup, @locale, member,
                                  step: "3", member: params))
    assert %{id: id} = redirected_params(conn)

    if member.step == 5 do
      assert redirected_to(conn) == member_path(conn, :show, @locale, id)
    else
      assert redirected_to(conn) == member_path(conn, :setup, @locale, id, step: "4")
    end
  end

  # test "step3_update with invalid params", %{conn: conn, member: member} do
  #   params = %{
  #     email: "",
  #     mobile: ""
  #   }

  #   conn = post(conn, member_path(conn, :update_setup, @locale, member,
  #                                 step: "3", member: params))

  #   assert html_response(conn, 200) =~ "Contact"
  # end

  test "step4 with valid member", %{conn: conn, account_group: account_group, member: member} do
    account = insert(:account, account_group: account_group)
    product = insert(:product, code: "code101")
    account_product = insert(:account_product, account: account,
                             product: product)
    insert(:member_product, member: member, account_product: account_product)

    conn = get(conn, member_path(conn, :setup, @locale, member, step: "4"))

    assert html_response(conn, 200) =~ member.first_name
    assert html_response(conn, 200) =~ account_group.code
  end

  test "member_cancel cancels member when params are valid", %{conn: conn, member: member} do
    params = %{
      member_id: member.id,
      cancel_date: "2017-10-15",
      cancel_reason: "Reason 1",
      cancel_remarks: "Remarks sample"
    }
    conn = post(conn, member_path(conn, :member_cancel, @locale, member: params))
    assert redirected_to(conn) == member_path(conn, :index, @locale)
  end

  test "member_suspend suspends member when params are valid", %{conn: conn, member: member} do
    params = %{
      member_id: member.id,
      suspend_date: "",
      suspend_reason: "",
      suspend_remarks: ""
    }
    conn = post(conn, member_path(conn, :member_suspend, @locale, member: params))
    assert redirected_to(conn) == member_path(conn, :index, @locale)
  end

  test "member_cancel reactivates member when params are valid", %{conn: conn, member: member} do
    params = %{
      member_id: member.id,
      reactivate_date: "2017-10-15",
      reactivate_reason: "Reason 1",
      reactivate_remarks: "Remarks sample"
    }
    conn = post(conn, member_path(conn, :member_reactivate, @locale, member: params))
    assert redirected_to(conn) == member_path(conn, :index, @locale)
  end

  #test "Test Batch processing index", %{conn: conn} do
  #  conn = get(conn, member_path(conn, :batch_processing_index, @locale))
  #  assert html_response(conn, 200) =~ "Batch Processing"
  #end

  test "Test Batch File upload is empty", %{conn: conn} do
    params = %{
      upload_type: "Corporate"
    }
    conn = post(conn, member_path(conn, :import_member, @locale, member: params))
    assert redirected_to(conn) == member_path(conn, :batch_processing_index, @locale)
  end

  test "get_member_logs return member logs", %{conn: conn, member: member, user: user} do
    MemberContext.create_member_log(user, member)
    conn = get(conn, member_path(conn, :get_member_logs, @locale, member.id))
    assert List.first(json_response(conn, 200))["message"] == "<b>masteradmin </b> enrolled a member named <b> <i>Test01  Test01 </b> </i>"
  end
end
