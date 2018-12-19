defmodule Innerpeace.PayorLink.Web.Api.V1.ProcedureControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase

  alias Innerpeace.Db.Base.Api.ProcedureContext
  alias PayorLink.Guardian.Plug
  alias Innerpeace.Db.{
    Repo,
    Schemas.PayorProcedure
  }

  setup do
    user = insert(:user, username: "masteradmin", password: "P@ssw0rd")
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = PayorLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)
    procedure2 = insert(:procedure, code: "A00.0", description: "Sample Description")

    {:ok, %{
      conn: conn,
      jwt: jwt,
      procedure: procedure2
    }}
  end

  test "/procedures, loads all records of procedure", %{conn: conn} do
    search_query = ""
    payor_procedures = ProcedureContext.get_all_queried_payor_procedures(search_query)

    params = %{
      "procedure": "sample"
    }

    conn =
      conn
      |> get(api_procedure_path(conn, :load_procedures, params))
    assert %{"procedures" => json_response(conn, 200)["procedures"]} == render_json("load_all_procedures.json", payor_procedures: payor_procedures)
  end

  test "/procedures, loads all records of procedure without authorization" do
    params = %{
      "procedure": "sample"
    }

    conn = build_conn()
    conn =
      conn
      |> get(api_procedure_path(conn, :load_procedures, params))
    assert json_response(conn, 401) == %{"error" => %{"message" => "Unauthorized"}}
  end

  test "post /procedures, creates procedure with valida parameters", %{conn: conn} do
    insert(:payor, name: "Maxicare")
    insert(:procedure, code: "procedure123")
    params = %{
      "standard_cpt_code": "procedure123",
      "code": "some code",
      "description": "some description",
      "general_exclusion": true
    }
    conn =
      conn
      |> post(api_procedure_path(conn, :create, params))
    pp = PayorProcedure |> Repo.get_by!(code: params.code) |> Repo.preload(:procedure)
    assert json_response(conn, 200) == render_json("payor_procedure.json", payor_procedure: pp)
  end

  test "post /procedures, does not create procedure with invalid parameters", %{conn: conn} do
    params = %{
      "standard_cpt_code": "procedure123",
      "code": "some code",
      "description": "some description",
      "general_exclusion": true
    }
    conn =
      conn
      |> post(api_procedure_path(conn, :create, params))
    assert json_response(conn, 400)["error"]["message"] =~ "standard_cpt_code is invalid"
  end

  test "get procedure returns procedure when id is valid", %{conn: conn, jwt: jwt} do
    procedure = insert(:procedure)
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get("/api/v1/#{procedure.id}/get_procedure")
    assert json_response(conn, 200)["description"] == "test_name"
  end

  test "get procedure returns error when id is invalid", %{conn: conn, jwt: jwt} do
    diagnosis = insert(:diagnosis)
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get("/api/v1/#{diagnosis.id}/get_procedure")
    assert json_response(conn, 404) == %{"error" => %{"message" => "Not Found"}}
  end

  test "get payor_procedure returns payor_procedure when id is valid", %{conn: conn, jwt: jwt} do
    procedure = insert(:procedure)
    payor_procedure = insert(:payor_procedure, procedure: procedure)
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get("/api/v1/#{payor_procedure.id}/get_payor_procedure")
    assert json_response(conn, 200)["standard_procedure"]["description"] == "test_name"
  end

  test "get payor_procedure returns error when id is invalid", %{conn: conn, jwt: jwt} do
    diagnosis = insert(:diagnosis)
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get("/api/v1/#{diagnosis.id}/get_payor_procedure")
    assert json_response(conn, 404) == %{"error" => %{"message" => "Not Found"}}
  end

  defp render_json(template, assigns) do
    assigns = Map.new(assigns)

    template
    |> Innerpeace.PayorLink.Web.Api.V1.ProcedureView.render(assigns)
    |> Poison.encode!
    |> Poison.decode!
  end

end
