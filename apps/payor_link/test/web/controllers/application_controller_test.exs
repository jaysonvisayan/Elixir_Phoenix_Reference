defmodule Innerpeace.PayorLink.Web.ApplicationControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  import Innerpeace.PayorLink.TestHelper

  setup do
    conn = build_conn()
    application = insert(:application, name: "PayorTest")
    user = insert(:user, is_admin: true)
    conn = sign_in(conn, user)
    {:ok, %{conn: conn, application: application}}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, application_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing Applications"
  end

  test "renders form for new applications", %{conn: conn} do
    conn = get conn, application_path(conn, :new)
    assert html_response(conn, 200) =~ "New Application"
  end

  test "creates application and redirects to show when data is valid", %{conn: conn} do
    conn = post conn, application_path(conn, :create), application: %{name: "some name"}

    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == application_path(conn, :show, id)

    conn = get conn, application_path(conn, :show, id)
    assert html_response(conn, 200) =~ "Show"
  end

  test "does not create application and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, application_path(conn, :create), application: %{name: nil}
    assert html_response(conn, 200) =~ "New Application"
  end

  test "renders form for editing chosen application", %{conn: conn, application: application} do
    conn = get conn, application_path(conn, :edit, application)
    assert html_response(conn, 200) =~ "Edit"
  end

  test "updates chosen application and redirects when data is valid", %{conn: conn, application: application} do
    conn = put conn, application_path(conn, :update, application), application: %{name: "some updated name"}
    assert redirected_to(conn) == application_path(conn, :show, application)

    conn = get conn, application_path(conn, :show, application)
    assert html_response(conn, 200) =~ "some updated name"
  end

  test "does not update chosen application and renders errors when data is invalid", %{conn: conn, application: application} do
    conn = put conn, application_path(conn, :update, application), application: %{name: nil}
    assert html_response(conn, 200) =~ "Edit"
  end

  test "deletes chosen application", %{conn: conn, application: application} do
    conn = delete conn, application_path(conn, :delete, application)
    assert redirected_to(conn) == application_path(conn, :index)
    assert_error_sent 404, fn ->
      get conn, application_path(conn, :show, application)
    end
  end
end
