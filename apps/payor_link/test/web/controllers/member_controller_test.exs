defmodule Innerpeace.PayorLink.Web.MemberControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper

  setup do
    conn = build_conn()
    # user = insert(:user, is_admin: true)
    # conn = sign_in(conn, user)
    user = fixture(:user_permission, %{keyword: "manage_members", module: "Members"})
    conn = authenticated(conn, user)
    account_group = insert(:account_group, name: "account101")
    insert(:account, account_group: account_group, status: "Active")
    insert(:coverage, name: "ACU", description: "ACU", status: "A", type: "A")
    member = insert(:member, %{
      first_name: "test",
      account_group: account_group
    })
    {:ok, %{conn: conn, member: member}}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, member_path(conn, :index)
    assert html_response(conn, 200) =~ "Members"
  end

  test "renders form for creating new member", %{conn: conn} do
    conn = get conn, member_path(conn, :new)
    assert html_response(conn, 200) =~ "Add Member"
  end

  test "creates new member and redirects to step 2 when data is valid", %{conn: conn} do
    account_group = insert(:account_group, code: "code101")
    params = %{
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
      for_card_issuance: true,
      skipping_hierarchy: [""]
    }
    conn = post conn, member_path(conn, :create_general), member: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == member_path(conn, :setup, id, step: "2")
  end

  test "does not create new member and renders errors when data is invalid", %{conn: conn} do
    params = %{}
    conn = post conn, member_path(conn, :create_general), member: params
    assert html_response(conn, 200) =~ "Add Member"
  end

  test "renders form for editing step 1 of the given member", %{conn: conn, member: member} do
    conn = get conn, member_path(conn, :setup, member, step: "1")
    assert html_response(conn, 200) =~ member.first_name
  end

  test "updates step 1 of given member with valid attributes", %{conn: conn, member: member} do
    account_group = insert(:account_group, code: "code101")
    params = %{
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
      for_card_issuance: true,
      skipping_hierarchy: [""]
    }
    conn = post conn, member_path(conn, :update_setup, member, step: "1", member: params)
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == member_path(conn, :setup, id, step: "2")
  end

  test "does not update step 1 of given member with invalid attributes", %{conn: conn, member: member} do
    params = %{
      for_card_issuance: true
    }
    conn = post conn, member_path(conn, :update_setup, member, step: "1", member: params)
    assert html_response(conn, 200) =~ member.first_name
  end

  test "renders form for editing step 2 of the given member", %{conn: conn, member: member} do
    conn = get conn, member_path(conn, :setup, member, step: "2")
    assert html_response(conn, 200) =~ "Products"
  end

  test "updates step 2 of given member with valid attributes", %{conn: conn, member: member} do
    account_product = insert(:account_product)
    params = %{
      "account_product_ids_main" => "#{account_product.id}"
    }
    conn = post conn, member_path(conn, :update_setup, member, step: "2", member: params)
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == member_path(conn, :setup, id, step: "2")
  end

  test "does not update step 2 of given member with invalid attributes", %{conn: conn, member: member} do
    params = %{
      "account_product_ids_main" => ""
    }
    conn = post conn, member_path(conn, :update_setup, member, step: "2", member: params)
    assert html_response(conn, 200) =~ "Products"
  end

  test "renders form for editing step 3 of the given member", %{conn: conn, member: member} do
    conn = get conn, member_path(conn, :setup, member, step: "3")
    assert html_response(conn, 200) =~ "Contact"
    assert html_response(conn, 200) =~ "Address"
  end

  test "updates step 3 of given member with valid attributes", %{conn: conn, member: member} do
    params = %{
      email: "antonvictorio@gmail.com",
      mobile: "123"
    }
    conn = post conn, member_path(conn, :update_setup, member, step: "3", member: params)
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == member_path(conn, :setup, id, step: "4")
  end

  test "does not update step 3 of given member with invalid attributes", %{conn: conn, member: member} do
    params = %{
      mobile: "123"
    }
    conn = post conn, member_path(conn, :update_setup, member, step: "3", member: params)
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == member_path(conn, :setup, id, step: "4")
  end

  test "renders step 4 form summary of the given member", %{conn: conn, member: member} do
    account_group = insert(:account_group)
    account = insert(:account, account_group: account_group)
    product = insert(:product, code: "code101")
    account_product = insert(:account_product, account: account, product: product)
    insert(:member_product, member: member, account_product: account_product)
    conn = get conn, member_path(conn, :setup, member, step: "4")
    assert html_response(conn, 200) =~ member.first_name
    assert html_response(conn, 200) =~ product.code
  end

  test "add member product on show page", %{conn: conn, member: member} do
    account_product = insert(:account_product)
    params = %{
      "account_product_ids_main" => "#{account_product.id}"
    }
    conn = post conn, member_path(conn, :add_member_product, member, member: params)
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == member_path(conn, :show, id, tab: "product")
  end

  test "deleting_member_product, deleting member product record", %{conn: conn} do
    member_product = insert(:member_product, tier: 1)
    conn = delete conn, member_path(conn, :delete_member_product, member_product.member_id, member_product.id)
    assert json_response(conn, 200) == Poison.encode!(%{
      valid: true
    })
  end

end
