defmodule Innerpeace.PayorLink.Web.CoverageControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper

  setup do
    conn = build_conn()
    coverage = insert(:coverage, name: "Coverage Test", description: "some content", status: "A", type: "A")
    # user = insert(:user, is_admin: true)
    # conn = sign_in(conn, user)
    user = fixture(:user_permission, %{keyword: "manage_coverages", module: "Coverages"})
    conn = authenticated(conn, user)
    {:ok, %{conn: conn, coverage: coverage}}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, coverage_path(conn, :index)
    assert html_response(conn, 200) =~ "Coverages"
  end

  test "renders form for new coverages", %{conn: conn} do
    conn = get conn, coverage_path(conn, :new)
    assert html_response(conn, 200) =~ "Coverage"
  end

  test "creates coverage and redirects to index when data is valid", %{conn: conn} do
    conn = post conn, coverage_path(conn, :create), coverage: %{code: "CODE", name: "Coverage Test", description: "some content", status: "A", type: "A"}

    assert redirected_to(conn) == coverage_path(conn, :index)

    conn = get conn, coverage_path(conn, :index)
    assert html_response(conn, 200) =~ "Coverages"
  end

  test "does not create coverage and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, coverage_path(conn, :create), coverage: %{name: nil}
    assert html_response(conn, 200) =~ "Coverage"
  end

  test "renders form for editing chosen coverage", %{conn: conn, coverage: coverage} do
    conn = get conn, coverage_path(conn, :edit, coverage)
    assert html_response(conn, 200) =~ "Edit"
  end

  test "updates chosen coverage and redirects when data is valid", %{conn: conn, coverage: coverage} do
    conn = put conn, coverage_path(conn, :update, coverage), coverage: %{code: "CODE", name: "Coverage Test", description: "some content", status: "A", type: "A"}
    assert redirected_to(conn) == coverage_path(conn, :index)

    conn = get conn, coverage_path(conn, :index)
    assert html_response(conn, 200) =~ "Coverages"
  end

  test "does not update chosen coverage and renders errors when data is invalid", %{conn: conn, coverage: coverage} do
    conn = put conn, coverage_path(conn, :update, coverage), coverage: %{name: nil}
    assert html_response(conn, 200) =~ "Edit"
  end

  test "deletes chosen coverage", %{conn: conn, coverage: coverage} do
    conn = delete conn, coverage_path(conn, :delete, coverage)
    assert redirected_to(conn) == coverage_path(conn, :index)
    assert_error_sent 404, fn ->
      get conn, coverage_path(conn, :show, coverage)
    end

  end
end
