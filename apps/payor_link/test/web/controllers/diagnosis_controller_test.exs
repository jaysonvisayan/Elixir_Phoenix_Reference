defmodule Innerpeace.PayorLink.Web.DiagnosisControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper

  setup do
    conn = build_conn()
    # user = insert(:user, is_admin: true)
    # conn = sign_in(conn, user)
    user = fixture(:user_permission, %{keyword: "manage_diseases", module: "Diseases"})
    conn = authenticated(conn, user)
    diagnosis = insert(:diagnosis)
    {:ok, %{conn: conn, diagnosis: diagnosis}}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, diagnosis_path(conn, :index)
    assert html_response(conn, 200) =~ "Diseases"
  end

  test "csv_export/1 exports data to csv", %{conn: conn} do
    conn = get conn, diagnosis_path(conn, :csv_export)
    assert response_content_type(conn, :csv) =~ "charset=utf-8"
  end

  test "edit renders edit page", %{conn: conn, diagnosis: diagnosis} do

    conn = get conn, diagnosis_path(conn, :edit, diagnosis.id)
    _result = html_response(conn, 200) =~ "Edit"
  end

  test "updates diagnosis with valid params", %{conn: conn, diagnosis: diagnosis} do
    params = %{
      exclusion_type: "",
      congenital: "N",
      code: "code"
    }

    conn = put conn, diagnosis_path(conn, :update, diagnosis.id), diagnosis: params
    result = get_flash(conn, :info)

    assert result == "Diagnosis updated successfully."
  end

  test "updates diagnosis with invalid params", %{conn: conn, diagnosis: diagnosis} do
    params = %{
      exclusion_type: "",
    }

    conn = put conn, diagnosis_path(conn, :update, diagnosis.id), diagnosis: params
    result = get_flash(conn, :error)

    assert result == "Error was encountered while saving diagnosis"
  end

  test "logs with valid diagnosis id", %{conn: conn, diagnosis: diagnosis} do
    user = insert(:user)
    diagnosis_log = insert(:diagnosis_log, diagnosis: diagnosis, user: user)
    conn = get conn, diagnosis_path(conn, :logs, diagnosis.id)
    result = json_response(conn, 200)
    assert result == Poison.encode!([diagnosis_log])
  end

  test "logs with invalid diagnosis id", %{conn: conn, diagnosis: diagnosis} do
    user = insert(:user)
    {_, id} = Ecto.UUID.load(Ecto.UUID.bingenerate)
    insert(:diagnosis_log, diagnosis: diagnosis, user: user)
    conn = get conn, diagnosis_path(conn, :logs, id)
    result = json_response(conn, 200)
    assert result == Poison.encode!([])
  end
end
