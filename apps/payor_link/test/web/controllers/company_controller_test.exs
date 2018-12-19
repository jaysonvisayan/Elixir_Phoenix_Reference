defmodule Innerpeace.PayorLink.Web.CompanyControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper

  # @create_attrs %{
  #   name: "AccountName",
  #   type: "Corporate",
  #   code: "AccountCode"
  # }
  setup do
    conn = build_conn()
    account = insert(:account, step: 1)
    insert(:account_group)
    # user = insert(:user, is_admin: true)
    # conn = sign_in(conn, user)
    user = fixture(:user_permission, %{keyword: "manage_company", module: "Company"})
    conn = authenticated(conn, user)
    {:ok, %{conn: conn, user: user, account: account}}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, company_path(conn, :index)
    assert html_response(conn, 200) =~ "Company"
  end

  test "renders form for new company", %{conn: conn} do
    conn = get conn, company_path(conn, :new)
    assert html_response(conn, 200) =~ "Add Company"
  end

  test "creates company and redirects to index when data is valid", %{conn: conn} do
    conn = post conn, company_path(conn, :create), company: %{name: "Company Name", code: "Company Code"}
    assert html_response(conn, 200) =~ "Companies"
  end

  test "does not create company and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, company_path(conn, :create), company: %{name: "nil", code: "nil"}
    assert html_response(conn, 200) =~ "Add Company"
  end

  test "Show company", %{conn: conn} do
    company = insert(:company, name: "test", code: "123")
    conn = get conn, company_path(conn, :show, company.id)

    assert html_response(conn, 200) =~ "Company Details"
  end
end
