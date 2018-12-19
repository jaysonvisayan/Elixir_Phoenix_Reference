defmodule Innerpeace.PayorLink.Web.ProcedureControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper

  setup do
    conn = build_conn()
    user = fixture(:user_permission, %{keyword: "manage_procedures", module: "Procedures"})
    conn = authenticated(conn, user)
    {:ok, %{conn: conn, user: user}}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, procedure_path(conn, :index)
    assert html_response(conn, 200) =~ "Procedures"
  end

  test "index load datatable", %{conn: conn} do
    payor = insert(:payor, %{name: "Maxicare"})
    procedure = insert(:procedure)
    insert(:payor_procedure, payor: payor, procedure: procedure, code: "code", description: "descript")
    conn = get conn, procedure_path(conn, :index_load_datatable, params: %{"search" => "", "offset" => 0})
    assert List.first(json_response(conn, 200))["code"] == "code"
  end

  test "renders form for creating new payor CPT", %{conn: conn} do
    insert(:payor, %{name: "Maxicare"})
    conn = get conn, procedure_path(conn, :new)
    assert html_response(conn, 200) =~ "Payor CPT Code"
    assert html_response(conn, 200) =~ "Payor CPT Description"
  end

  test "creates new payor CPT and redirects to index when data is valid", %{conn: conn} do
    insert(:payor, %{name: "Maxicare"})
    procedure = insert(:procedure)
    params = %{
      code: "some code",
      description: "some description",
      procedure_id: procedure.id
    }
    conn = post conn, procedure_path(conn, :create_cpt), payor_procedure: params
    assert redirected_to(conn) == procedure_path(conn, :index)
  end

  test "does not create new payor CPT and renders errors when data is invalid", %{conn: conn} do
    insert(:payor, %{name: "Maxicare"})
    conn = post conn, procedure_path(conn, :create_cpt), payor_procedure: %{}
    assert html_response(conn, 200) =~ "Payor CPT Code"
    assert html_response(conn, 200) =~ "Payor CPT Code"
  end

  # test "does not update payor CPT and renders errors when data is invalid(null_bytes)", %{conn: conn} do
  #   payor = insert(:payor, %{name: "Maxicare"})
  #   procedure = insert(:procedure)
  #   payor_procedure = insert(:payor_procedure, payor: payor, procedure: procedure, code: "code", description: "descript")
  #   conn = put(conn, procedure_path(conn, :update_cpt, payor_procedure.id), payor_procedure: %{description: "\x00"})
  #   assert redirected_to(conn) == procedure_path(conn, :new)
  # end

  test "deactivates chosen payor procedure", %{conn: conn} do
    payor = insert(:payor, %{name: "Maxicare"})
    procedure = insert(:procedure)
    payor_procedure = insert(:payor_procedure, payor: payor, procedure: procedure, code: "code", description: "descript")
    params = %{
      payor_procedure_id: payor_procedure.id
    }
    conn = post conn, procedure_path(conn, :deactivate_cpt, payor_procedure: params)
    assert redirected_to(conn) == procedure_path(conn, :index)
  end

  # test "export  CPT and redirects to index when data is valid", %{conn: conn} do
  #     file_upload = %Plug.Upload{content_type: "text/csv", path: "test/file/testcpt.csv", filename: "testcpt.csv"}
  #     raise file_upload
  #     params = %{
  #       file: "some text"
  #     }

  #     conn = post conn, procedure_path(conn, :export_cpt,
  #     payor_procedure: %Plug.Upload{content_type: "text/csv",
  #     path: "test/file/testcpt.csv", filename: "testcpt.csv"} )
  #     assert redirected_to(conn) == procedure_path(conn, :index)
  # end

  test "index load datatable without parameters", %{conn: conn} do
    conn = get conn, procedure_path(conn, :index_load_datatable, params: %{})
    assert (json_response(conn, 404)) == %{"error" => %{"message" => "Not Found"}}
  end
end
