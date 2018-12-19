defmodule Innerpeace.PayorLink.Web.Api.V1.ExclusionControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase

  # alias Innerpeace.Db.Base.Api.ExclusionContext
  alias PayorLink.Guardian.Plug

  setup do
    user = insert(:user, username: "masteradmin", password: "P@ssw0rd")
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = PayorLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)

    {:ok, %{conn: conn, jwt: jwt}}
  end

  test "lists all entries on index", %{conn: conn, jwt: jwt} do
    exclusion = insert(:exclusion, name: "general-exclusion-maxicare1", code: "genex-101")
    payor_procedure = insert(:payor_procedure)
    disease = insert(:diagnosis, code: "icd101", description: "dengue")
    insert(:exclusion_procedure, procedure: payor_procedure, exclusion: exclusion)
    insert(:exclusion_diseases, disease: disease, exclusion: exclusion)
    exclusion = Innerpeace.Db.Base.ExclusionContext.get_exclusion(exclusion.id)

    exclusion2 = insert(:exclusion, name: "general-exclusion-maxicare2", code: "genex-102")
    payor_procedure = insert(:payor_procedure)
    disease = insert(:diagnosis, code: "icd102", description: "dengue")
    insert(:exclusion_procedure, procedure: payor_procedure, exclusion: exclusion2)
    insert(:exclusion_diseases, disease: disease, exclusion: exclusion2)
    exclusion2 = Innerpeace.Db.Base.ExclusionContext.get_exclusion(exclusion2.id)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(api_exclusion_path(conn, :index))


    assert %{"data" => Enum.sort(json_response(conn, 200)["data"])} == render_json("index.json", exclusions: Enum.sort([exclusion, exclusion2]))
  end

  test "search entries on index", %{conn: conn, jwt: jwt} do
    exclusion = insert(:exclusion, name: "general-exclusion-maxicare1", code: "genex-101")
    payor_procedure = insert(:payor_procedure)
    disease = insert(:diagnosis, code: "icd101", description: "dengue")
    insert(:exclusion_procedure, procedure: payor_procedure, exclusion: exclusion)
    insert(:exclusion_diseases, disease: disease, exclusion: exclusion)
    exclusion = Innerpeace.Db.Base.ExclusionContext.get_exclusion(exclusion.id)

    exclusion2 = insert(:exclusion, name: "general-exclusion-maxicare2", code: "genex-102")
    payor_procedure = insert(:payor_procedure)
    disease = insert(:diagnosis, code: "icd102", description: "dengue")
    insert(:exclusion_procedure, procedure: payor_procedure, exclusion: exclusion2)
    insert(:exclusion_diseases, disease: disease, exclusion: exclusion2)
    exclusion2 = Innerpeace.Db.Base.ExclusionContext.get_exclusion(exclusion2.id)

    params = %{"exclusion" => "general"}
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(api_exclusion_path(conn, :index), params)
    assert %{"data" => Enum.sort(json_response(conn, 200)["data"])} == render_json("index.json", exclusions: Enum.sort([exclusion, exclusion2]))
  end

  test "search entries on index with invalid params - exclusion without value", %{conn: conn, jwt: jwt} do
    exclusion = insert(:exclusion, name: "general-exclusion-maxicare1", code: "genex-101")
    payor_procedure = insert(:payor_procedure)
    disease = insert(:diagnosis, code: "icd101", description: "dengue")
    insert(:exclusion_procedure, procedure: payor_procedure, exclusion: exclusion)
    insert(:exclusion_diseases, disease: disease, exclusion: exclusion)
    _exclusion = Innerpeace.Db.Base.ExclusionContext.get_exclusion(exclusion.id)

    exclusion2 = insert(:exclusion, name: "general-exclusion-maxicare2", code: "genex-102")
    payor_procedure = insert(:payor_procedure)
    disease = insert(:diagnosis, code: "icd102", description: "dengue")
    insert(:exclusion_procedure, procedure: payor_procedure, exclusion: exclusion2)
    insert(:exclusion_diseases, disease: disease, exclusion: exclusion2)
    _exclusion2 = Innerpeace.Db.Base.ExclusionContext.get_exclusion(exclusion2.id)

    params = %{"exclusion" => nil}
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{jwt}")
        |> get(api_exclusion_path(conn, :index), params)
    assert json_response(conn, 404) == %{"error" => %{"message" => "Please input exclusion name or exclusion code."}}
  end

  test "lists all entries on index without token", %{conn: conn} do
    conn =
      build_conn()
      |> get(api_exclusion_path(conn, :index))

    assert json_response(conn, 401) == %{"error" => %{"message" => "Unauthorized"}}
  end

  test "create_exclusion_api/2, inserts an exclusion record. Batch upload with valid parameters", %{conn: conn, jwt: jwt} do
    procedure = insert(:payor_procedure, code: "P123")
    disease = insert(:diagnosis, code: "D123")
    params = %{
      "params" => %{
        "coverage" => "General",
        "disease" => [disease.code],
        "procedure" => [procedure.code]
      }
    }

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_exclusion_path(conn, :create_general_exclusion_api), params)

    result = %{
      "disease" => [
        %{
          "code" => disease.code,
          "description" => disease.description
        }
      ],
      "procedures" => [
        %{
          "code" => procedure.code,
          "description" => procedure.description
        }
      ]
    }

    assert json_response(conn, 200) == result
  end

  test "create_exclusion_api/2, inserts an exclusion record. Batch upload with invalid parameters", %{conn: conn, jwt: jwt} do
    params = %{
      "params" => %{
        "coverage" => "General",
        "disease" => ["D123"],
        "procedure" => ["P123"]
      }
    }

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_exclusion_path(conn, :create_general_exclusion_api), params)

    result = %{
      "errors" => %{
        "disease" => [
          List.first(params["params"]["disease"]) <> " does not exist."
        ],
        "procedure" => [
          List.first(params["params"]["procedure"]) <> " does not exist."
        ]
      }
    }

    assert json_response(conn, 404) == result
  end

    test "create_exclusion_api/2, inserts an exclusion record. Pre-existing condition with valid parameters", %{conn: conn, jwt: jwt} do
      disease = insert(:diagnosis, code: "D123", exclusion_type: "Pre-existing condition", type: "Dreaded")
      duration = %{
        "disease_type" => "dreaded",
        "duration" => "100",
        "covered_after_duration" => "Percentage",
        "value" => "50"
      }

      params = %{
        "params" => %{
          "coverage" => "Pre-existing Condition",
          "code" => "PRECON101",
          "name" => "Sample Pre-existing Condition",
          "duration" => [duration],
          "disease" => [disease.code]
        }
      }

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{jwt}")
        |> post(api_exclusion_path(conn, :create_custom_exclusion_api), params)

      result = json_response(conn, 200)
      assert result["code"] == "PRECON101"
      assert result["name"] == "Sample Pre-existing Condition"
    end

  test "create_exclusion_api/2, inserts an exclusion record. Pre-existing condition with invalid parameters", %{conn: conn, jwt: jwt} do
    disease = insert(:diagnosis, code: "D123")
    duration = %{
      "disease_type" => "dreaded",
      "duration" => "100",
      "covered_after_duration" => "Percentage",
      "value" => "50"
    }

    params = %{
      "params" => %{
        "coverage" => "Pre-existing Condition",
        "code" => "PRECON101",
        "name" => "Sample Pre-existing Condition",
        "duration" => [duration],
        "disease" => [disease.code]
      }
    }

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_exclusion_path(conn, :create_custom_exclusion_api), params)

    result = json_response(conn, 404)
    assert List.first(result["errors"]["disease"]) == "D123's exclusion type is not Pre-existing condition.'"
  end

  test "create_exclusion_api/2, inserts an exclusion record. eneral Exclusion with valid parameters", %{conn: conn, jwt: jwt} do
    disease = insert(:diagnosis, code: "D123", exclusion_type: "General Exclusion", type: "Dreaded")
    procedure = insert(:payor_procedure, code: "P123", exclusion_type: "General Exclusion")
    params = %{
      "params" => %{
        "coverage" => "General Exclusion",
        "code" => "Genex101",
        "name" => "Sample General Exclusion",
        "procedure" => [procedure.code],
        "disease" => [disease.code]
      }
    }

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_exclusion_path(conn, :create_custom_exclusion_api), params)

    result = json_response(conn, 200)
    assert result["code"] == "Genex101"
    assert result["name"] == "Sample General Exclusion"
  end

  test "create_exclusion_api/2, inserts an exclusion record. General Exclusion with invalid parameters", %{conn: conn, jwt: jwt} do
    params = %{
      "params" => %{
        "coverage" => "General Exclusion",
        "code" => "Genex101",
        "name" => "Sample General Exclusion",
        "procedure" => ["test"],
        "disease" => ["test"]
      }
    }

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_exclusion_path(conn, :create_custom_exclusion_api), params)

    result = json_response(conn, 404)
    assert List.first(result["errors"]["disease"]) == "test does not exist."
    assert List.first(result["errors"]["procedure"]) == "test does not exist."
  end

  defp render_json(template, assigns) do
    assigns = Map.new(assigns)

    template
    |> Innerpeace.PayorLink.Web.Api.V1.ExclusionView.render(assigns)
    |> Poison.encode!
    |> Poison.decode!
  end

end
