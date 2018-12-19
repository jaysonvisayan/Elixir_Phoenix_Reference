defmodule Innerpeace.PayorLink.Web.RUVControllerTest do
  use Innerpeace.{
    PayorLink.Web.ConnCase
  }

  # import Innerpeace.PayorLink.TestHelper

  setup do
    conn = build_conn()

    # user = insert(:user, is_admin: true)
    user = fixture(:user_permission, %{keyword: "manage_ruvs", module: "RUVs"})
    ruv = insert(:ruv,
                 code: "test code",
                 description: "test description",
                 type: "Unit",
                 value: "20",
                 effectivity_date: Ecto.Date.cast!("2017-10-10"),
                 created_by_id: user.id,
                 updated_by_id: user.id)
    ruv_log = insert(:ruv_log, ruv: ruv, user: user, message: "test message logs")

    conn = authenticated(conn, user)
    {:ok, %{conn: conn, user: user, ruv: ruv, ruv_log: ruv_log}}
  end

  test "index renders form for index", %{conn: conn} do
    conn = get conn, ruv_path(conn, :index)
    result = html_response(conn, 200)
    assert result =~ "RUV"
  end

  test "new renders form for creating ruv", %{conn: conn} do
    conn = get conn, ruv_path(conn, :new)
    result = html_response(conn, 200)
    assert result =~ "Add RUV"
  end

  test "create creates ruv and redirects to index when params is valid", %{conn: conn} do
    params = %{
      "code" => "test code",
      "description" => "test description",
      "type" => "Rate",
      "value" => 20,
      "effectivity_date" => Ecto.Date.cast!("2017-10-10")
    }

    conn = post conn, ruv_path(conn, :create), ruv: params
    result = redirected_to(conn)
    message_result = get_flash(conn, :info)

    assert message_result == "RUV has been successfully created."
    assert result == "/ruvs"
  end

  test "create display error message when params is invalid", %{conn: conn} do
    params = %{
      "code" => "test code",
      "description" => "test description",
      "type" => "Rate",
      "effectivity_date" => Ecto.Date.cast!("2017-10-10")
    }

    conn = post conn, ruv_path(conn, :create), ruv: params
    message_result = get_flash(conn, :error)

    assert message_result == "Error creating RUV! Please check the errors below."
  end

  test "edit renders form for updating ruv", %{conn: conn, ruv: ruv} do
    conn = get conn, ruv_path(conn, :edit, ruv.id)
    result = html_response(conn, 200)
    assert result =~ "Edit RUV"
  end

  test "update updates ruv and redirect to index when params is valid", %{conn: conn, ruv: ruv} do
    params = %{
      "description" => "test description update",
      "type" => "Rate",
    }

    conn = put conn, ruv_path(conn, :update, ruv), ruv: params
    result = redirected_to(conn)
    message_result = get_flash(conn, :info)

    assert message_result == "RUV has been updated successfully."
    assert result == "/ruvs"
  end

  test "update display error message when params is invalid", %{conn: conn, ruv: ruv} do
    params = %{
      "value" => "test"
    }

    conn = put conn, ruv_path(conn, :update, ruv), ruv: params
    message_result = get_flash(conn, :error)

    assert message_result == "Error updating RUV! Please check the errors below."
  end

  test "logs returns ruv logs with valid ruv id", %{conn: conn, ruv: ruv, ruv_log: ruv_log} do
    conn = get conn, ruv_path(conn, :logs, ruv)
    result = json_response(conn, 200)

    assert List.first(result)["message"] == ruv_log.message
  end

  test "logs does not return ruv logs", %{conn: conn} do
    ruv = insert(:ruv)
    conn = get conn, ruv_path(conn, :logs, ruv)
    result = json_response(conn, 200)

    assert result ==  []
  end

  test "delete deletes ruv and redirects to index when id is valid", %{conn: conn, ruv: ruv} do
    conn = get conn, ruv_path(conn, :delete, ruv)
    result = redirected_to(conn)
    message_result = get_flash(conn, :info)

    assert result == "/ruvs"
    assert message_result == "RUV removed successfully."
  end
end
