defmodule Innerpeace.PayorLink.Web.CaseRateControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper


  alias Innerpeace.Db.Base.Api.UtilityContext

  setup do
    conn = build_conn()
    # user = insert(:user, is_admin: true)
    # conn = sign_in(conn, user)
    case_rate = insert(:case_rate)
    insert(:diagnosis)
    insert(:ruv)
    user = fixture(:user_permission, %{keyword: "manage_caserates", module: "CaseRates"})
    conn = authenticated(conn, user)
    {:ok, %{conn: conn, case_rate: case_rate}}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, case_rate_path(conn, :index)
    assert html_response(conn, 200) =~ "Case Rates"
  end

  test "edit renders edit page", %{conn: conn, case_rate: case_rate} do
    conn = get conn, case_rate_path(conn, :edit, case_rate.id)
    _result = html_response(conn, 200) =~ "Edit"
  end

  test "creates case rate and redirects to index when data is valid", %{conn: conn} do
    diagnosis = insert(:diagnosis)
    params = %{
        "type" => "ICD",
        "description" => "Test",
        "hierarchy" => "1",
        "discount_percentage" => "100",
        "diagnosis_id" => diagnosis.id
       }
    conn = post conn, case_rate_path(conn, :create), case_rate: params
    assert redirected_to(conn) == case_rate_path(conn, :index)
  end

  test "logs with valid case_rate id", %{conn: conn, case_rate: case_rate} do
    user = insert(:user)
    case_rate_log = insert(:case_rate_log, case_rate: case_rate, user: user, message: "")
    conn = get conn, case_rate_path(conn, :show_logs, case_rate.id)
    result = json_response(conn, 200)
    csr =
      %{
        "case_rate_logs" => [
          %{
            "message" => case_rate_log.message,
            "inserted_at" => UtilityContext.sanitize_value(case_rate_log.inserted_at)
          }
        ]
      }
    assert result == csr
  end

  test "logs with invalid case_rate id", %{conn: conn, case_rate: case_rate} do
    user = insert(:user)
    {_, id} = Ecto.UUID.load(Ecto.UUID.bingenerate)
    insert(:case_rate_log, case_rate: case_rate, user: user)
    conn = get conn, case_rate_path(conn, :show_logs, id)
    result = json_response(conn, 200)
    assert result["case_rate_logs"] == []
  end
end
