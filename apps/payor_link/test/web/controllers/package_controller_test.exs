defmodule Innerpeace.PayorLink.Web.PackageControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper

  # @create_attrs %{
  #   name: "PackageName",
  #   code: "PackageCode"
  # }
  setup do
    conn = build_conn()
    account = insert(:account, step: 1)
    insert(:account_group)
    user = fixture(:user_permission, %{keyword: "manage_packages", module: "Packages"})
    conn = authenticated(conn, user)
    {:ok, %{conn: conn, user: user, account: account}}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, package_path(conn, :index)
    assert html_response(conn, 200) =~ "Packages"
  end

  test "renders form for new packages", %{conn: conn} do
    conn = get conn, package_path(conn, :new)
    assert html_response(conn, 200) =~ "Add Package"
  end

  test "creates package and redirects to show when data is valid", %{conn: conn} do
    conn = post conn, package_path(conn, :create), package: %{name: "Package Name", code: "Package Code", step: 2}
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == "/packages/#{id}/setup?step=2"
  end

  test "does not create pacakge and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, package_path(conn, :create), package: %{name: "nil"}
    assert html_response(conn, 200) =~ "Add Package"
  end

  test "updates chosen pacakge and redirects when data is valid", %{conn: conn} do
    package = insert(:package)
    conn = put conn, package_path(conn, :update_setup, package, step: 1),
      package: %{code: "Code", name: "Test"}
    assert redirected_to(conn) == "/packages/#{package.id}/setup?step=2"
  end

  test "deletes chosen package", %{conn: conn} do
    package = insert(:package)
    conn = delete conn, package_path(conn, :delete, package)
    assert redirected_to(conn) == package_path(conn, :index)
    assert_error_sent 500, fn ->
      delete conn, package_path(conn, :delete, package)
    end
  end

  test "renders form for step 2 of the given package", %{conn: conn} do
    package = insert(:package)
    procedure = insert(:procedure)
    insert(:payor_procedure, procedure: procedure)
    conn = get conn, package_path(conn, :setup, package, step: "2")
    assert html_response(conn, 200) =~ "Procedures"
  end

  test "step 2 adds package payor procedure with valid attributes", %{conn: conn} do
    package = insert(:package)
    procedure = insert(:procedure)
    payor_procedure = insert(:payor_procedure, procedure: procedure)
    params = %{
      "package_id" => package.id,
      "payor_procedure_id" => payor_procedure.id,
      "male" => true,
      "female" => true,
      "age_from" => "10",
      "age_to" => "15"
    }
    conn = post conn, package_path(conn, :update_setup, package, step: "2", package: params)
    assert redirected_to(conn) == package_path(conn, :setup, package, step: "2")
  end

  test "renders form for step 3 of the given package", %{conn: conn} do
    package = insert(:package)
    procedure = insert(:procedure)
    payor_procedure = insert(:payor_procedure, procedure: procedure)
    insert(:package_payor_procedure, payor_procedure: payor_procedure, package: package)
    conn = get conn, package_path(conn, :setup, package, step: "3")
    assert html_response(conn, 200) =~ "Package"
    assert html_response(conn, 200) =~ "Procedure"
  end
  test "edit_general, updating package general tab with valid attrs", %{conn: conn} do
    package = insert(:package)

    params = %{
      "name" => "Package Name",
      "code" => "Package Code"
    }
    conn = put conn, package_path(conn, :update_edit_setup, package, tab: "general", package: params)
    assert redirected_to(conn) == package_path(conn, :edit, package, tab: "general")
  end

  describe "edit package" do
    test "redirect to show page when valid params", %{conn: conn} do
      package = insert(:package)

      params = %{
        "id" => package.id
      }
      conn = put conn, package_path(conn, :edit, package, tab: "general", package: params)
      assert html_response(conn, 200) =~ "Procedures"
    end

    test "redirect to show page when invalid params", %{conn: conn} do
      package = insert(:package)

      conn = get conn, package_path(conn, :edit, package, id: package.id)
      assert redirected_to(conn) == "/packages/#{package.id}"
    end

    test "redirect to show page when invalid tab value", %{conn: conn} do
      package = insert(:package)

      params = %{
        "name" => ""
      }
      conn = put conn, package_path(conn, :update_edit_setup, package, tab: "NONEXISTING", package: params)
      assert redirected_to(conn) == "/packages/#{package.id}"
    end

    test "general tab does not update package with invalid attrs", %{conn: conn} do
      package = insert(:package)

      params = %{
        "name" => ""
      }
      conn = put conn, package_path(conn, :update_edit_setup, package, tab: "general", package: params)
      assert html_response(conn, 200) =~ "Package"
    end
  end


  describe "setup package" do
    test "redirect to show page when invalid params", %{conn: conn} do
      package = insert(:package)

      conn = get conn, package_path(conn, :setup, package, id: package.id)
      assert redirected_to(conn) == "/packages/#{package.id}"
    end

    test "redirect to index page when step is not integer and not valid", %{conn: conn} do
      package = insert(:package)

      conn = get conn, package_path(conn, :setup, package, id: package.id, step: "asdasd")
      assert redirected_to(conn) == "/packages"
    end

    test "redirect to step2", %{conn: conn} do
      package = insert(:package)

      conn = get conn, package_path(conn, :setup, package, id: package.id, step: 2)
      assert html_response(conn, 200) =~ "Package"
    end
  end
end
