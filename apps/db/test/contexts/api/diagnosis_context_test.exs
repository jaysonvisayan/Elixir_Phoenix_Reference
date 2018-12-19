defmodule Innerpeace.Db.Base.Api.DiagnosisContextTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.{
    Base.Api.DiagnosisContext
  }

  test "search_all_diagnosis*" do
    diagnosis = insert(:diagnosis)

    left =
      DiagnosisContext.search_all_diagnosis

    right =
      diagnosis
      |> List.wrap

    assert left == right
  end

  test "search a diagnosis using valid attributes*" do
    diagnosis = insert(:diagnosis, code: "SAMPLECODE")
    params = %{
      "diagnosis" => "SAMPLECODE"
    }
    left =
      params
      |> DiagnosisContext.search_diagnosis()

    right =
      diagnosis
      |> List.wrap

    assert left == right
  end

  test " validate_insert/2 returns diagnosis using valid attributes" do
     user = insert(:user)

     params = %{
        "code" => "A06.1",
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

     assert {:ok, _diagnoses} = DiagnosisContext.validate_insert(user, params)
  end

  test "get_diagnosis*" do
    diagnosis = insert(:diagnosis)

    assert diagnosis.id == DiagnosisContext.get_diagnosis(diagnosis.id).id
  end

  test "get_diagnosis_by_name/1 success" do
    insert(:diagnosis, description: "Salmonella", code: "A00.1")
    refute Enum.empty?(DiagnosisContext.get_diagnosis_using_name("A00.1"))
  end

  test "get_diagnosis_by_name/1 failed" do
    insert(:diagnosis, name: "TYPHOID")
    assert Enum.empty?(DiagnosisContext.get_diagnosis_using_name("sal"))
  end

  test "get_100_diagnosis/0 success" do
    insert(:diagnosis, description: "Salmonella")
    refute Enum.empty?(DiagnosisContext.get_diagnosis_using_name("sal"))
  end

  test "get_100_diagnosis/0 failed" do
    insert(:diagnosis, name: "TYPHOID")
    assert Enum.empty?(DiagnosisContext.get_diagnosis_using_name("sal"))
  end
end
