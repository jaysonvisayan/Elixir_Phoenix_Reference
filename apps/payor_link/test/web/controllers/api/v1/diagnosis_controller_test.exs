defmodule Innerpeace.PayorLink.Web.Api.V1.DiagnosisControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase

  # alias Innerpeace.Db.Base.Api.DiagnosisContext
  alias PayorLink.Guardian.Plug

  setup do
    user = insert(:user, username: "masteradmin", password: "P@ssw0rd")
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = PayorLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)
    diagnosis2 = insert(:diagnosis, code: "A00.0", description: "Sample Description")

    {:ok, %{
      conn: conn,
      jwt: jwt,
      diagnosis: diagnosis2
    }}
  end

  test "lists all entries on index", %{conn: conn, diagnosis: diagnosis2, jwt: jwt} do
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(api_diagnosis_path(conn, :index))
    assert %{"data" => json_response(conn, 200)["data"]} == render_json("index.json", diagnoses: [diagnosis2])
  end

  test "search entries on index", %{conn: conn, diagnosis: diagnosis2, jwt: jwt} do

    diagnosis = "Sample Description"

    params = %{"diagnosis" => diagnosis}
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(api_diagnosis_path(conn, :index), params)
    assert %{"data" => json_response(conn, 200)["data"]} == render_json("index.json", diagnoses: [diagnosis2])
  end

  test "search entries on index with invalid params - diagnosis without value", %{conn: conn, jwt: jwt} do

    diagnosis = ""

    params = %{"diagnosis" => diagnosis}
    if Map.has_key?(params, "diagnosis") == true and is_nil(params["diagnosis"]) do
      conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(api_diagnosis_path(conn, :search), params)
      assert json_response(conn, 404) == %{"error" => %{"message" => "Please input diagnosis description or code."}}
    end
  end

  test "search entries", %{conn: conn, diagnosis: diagnosis2, jwt: jwt} do
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(api_diagnosis_path(conn, :index))
    assert %{"data" => json_response(conn, 200)["data"]} == render_json("index.json", diagnoses: [diagnosis2])
  end

  test "create diagnosis returns diagnosis struct when params are valid", %{conn: conn, jwt: jwt} do
    insert(:diagnosis)
    params = %{
      "code" => "A06.3",
      "name" => "TYPHOID AND PARATYPHOID FEVERS: Paratyphoid fever ZA",
      "classification" => "string",
      "type" => "Dreaded",
      "group_description" => "string",
      "description" => "string",
      "congenital" => "Yes",
      "exclusion_type" => "General Exclusion",
      "group_name" => "string",
      "group_code" => "string",
      "chapter" => "string"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_diagnosis_path(conn, :create_diagnosis_api, params: params))
    assert json_response(conn, 200)
  end

  test "create diagnosis returns diagnosis struct when params are invalid", %{conn: conn, jwt: jwt} do
    insert(:diagnosis)
    params = %{
      "classification" => "string",
      "type" => "Dreaded",
      "group_description" => "string",
      "description" => "string",
      "congenital" => "Yes",
      "exclusion_type" => "General Exclusion",
      "group_name" => "string",
      "group_code" => "string",
      "chapter" => "string"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_diagnosis_path(conn, :create_diagnosis_api, params: params))
    assert json_response(conn, 404)["errors"]
  end

  test "get diagnosis returns diagnosis when id is valid", %{conn: conn, jwt: jwt} do
    diagnosis = insert(:diagnosis)
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get("/api/v1/#{diagnosis.id}/get_diagnosis")
    assert json_response(conn, 200)["data"]["description"] == "test"
  end

  test "get diagnosis returns error when id is invalid", %{conn: conn, jwt: jwt} do
    procedure = insert(:procedure)
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get("/api/v1/#{procedure.id}/get_diagnosis")
    assert json_response(conn, 404) == %{"error" => %{"message" => "Not Found"}}
  end

  test "get diagnosis using name returns list of diagnosis when valid", %{conn: conn, jwt: jwt} do
    insert(:diagnosis, name: "TYPHOID")
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get("/api/v1/diagnoses/name")
    assert Enum.count(json_response(conn, 200)["data"]) >= 2
  end

  test "get diagnosis using name with params returns list of diagnosis when valid", %{conn: conn, jwt: jwt} do
    insert(:diagnosis, description: "TYPHOID")
    params = %{name: "typ"}
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get("/api/v1/diagnoses/name", params)
    assert Enum.count(json_response(conn, 200)["data"]) == 1
  end

  defp render_json(template, assigns) do
    assigns = Map.new(assigns)

    template
    |> Innerpeace.PayorLink.Web.Api.V1.DiagnosisView.render(assigns)
    |> Poison.encode!
    |> Poison.decode!
  end
end
