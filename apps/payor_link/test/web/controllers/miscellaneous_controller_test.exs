defmodule Innerpeace.PayorLink.Web.MiscellaneousTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper

  setup do
    conn = build_conn()
    user = fixture(:user_permission, %{keyword: "manage_miscellaneous", module: "Miscellaneous"})
    conn = authenticated(conn, user)
    miscellaneous = insert(:miscellaneous,
                           code: "M0001",
                           description: "cotton",
                           created_by_id: user.id,
                           updated_by_id: user.id
    )
    # conn = sign_in(conn, user)
    {:ok, %{conn: conn, miscellaneous: miscellaneous}}
  end

  test "new, render form for creating new miscellaneous", %{conn: conn} do
    conn = get conn, miscellaneous_path(conn, :new)
    assert html_response(conn, 200) =~ "Miscellaneous"
  end

  test "index, list all entries on index", %{conn: conn, miscellaneous: miscellaneous} do
    conn = get conn, miscellaneous_path(conn, :index)
    assert html_response(conn, 200) =~ "Miscellaneous"
    assert html_response(conn, 200) =~ miscellaneous.code
  end

  test "create_general, creates miscellaneous with valid attributes and redirect in index", %{conn: conn} do
    params = %{
      "code" => "M0002",
      "description" => "Gloves",
      "price" => "10"
    }
    conn = post conn, miscellaneous_path(conn, :create_general), miscellaneous: params
    assert html_response(conn, 200) =~ "Miscellaneous"
  end

  test "edit, redirect to edit page", %{conn: conn, miscellaneous: miscellaneous} do
    conn = get conn, miscellaneous_path(conn, :edit, miscellaneous.id)
    assert html_response(conn, 200) =~ "Miscellaneous"
  end

  test "save_edit, save edited record", %{conn: conn, miscellaneous: miscellaneous}  do
    params = %{
      "code" => "M0002",
      "description" => "Gloves",
      "price" => "10"
    }
    conn = put conn, miscellaneous_path(conn, :save_edit, miscellaneous.id, miscellaneous: params)
    assert redirected_to(conn) == miscellaneous_path(conn, :index)
  end

end
