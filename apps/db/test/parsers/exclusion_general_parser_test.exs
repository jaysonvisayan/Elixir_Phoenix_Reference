defmodule Innerpeace.Db.Parsers.ExclusionGeneralParserTest do
  use Innerpeace.Db.SchemaCase, async: true
  # alias Innerpeace.Db.{
  #   Repo,
  #   Schemas.PayorProcedure,
  #   Schemas.Diagnosis,
  # }

  alias Innerpeace.Db.Parsers.ExclusionGeneralParser

  setup do
    user = insert(:user)
    insert(:diagnosis, code: "A02.2", description: "diagnosis1", exclusion_type: "Pre-existing condition")
    insert(:diagnosis, code: "A05.0", description: "diagnosis2")
    insert(:diagnosis, code: "A02.1", description: "diagnosis3", exclusion_type: "General Exclusion")

    ## already used
    insert(:payor_procedure, code: "LAB0503004", description: "procedure1")
    ## already used
    insert(:payor_procedure, code: "S2196", description: "procedure2")

    insert(:payor_procedure, code: "LAB6764", description: "procedure3", exclusion_type: "General Exclusion")
    insert(:payor_procedure, code: "LAB1220", description: "procedure4", exclusion_type: "General Exclusion")

    {:ok, %{
      user: user
    }}
  end


  #  test "Parse Exclusion General CSV returns ok", %{user: user} do
  #    filename = "Exclusion_Batch_Upload.csv"
  #
  #    map1 = {:ok, %{"Diagnosis Code" => "", "Payor CPT Code" => "S2196"}}
  #    map2 = {:ok, %{"Diagnosis Code" => "A02.2", "Payor CPT Code" => "LAB0503004"}}
  #    map3 = {:ok, %{"Diagnosis Code" => "A05.0", "Payor CPT Code" => ""}}
  #    map4 = {:ok, %{"Diagnosis Code" => "A02.1", "Payor CPT Code" => "LAB1220"}}
  #
  #    data = [map1, map2, map3, map4]
  #
  #    assert :ok == ExclusionGeneralParser.parse_data(data, filename, user.id)
  #  end

  test "Parse Exclusion General CSV, validate/1 method scenario1" do
    #### blank diagnosis code  #### correct cpt code
    params = %{"Diagnosis Code" => "", "Payor CPT Code" => "S2196"}

    {:ok, result} = ExclusionGeneralParser.validate(params)
    {:ok, payor_procedure} = result.payor_cpt_status
    assert {:ok, result} == {:ok, %{diagnosis_status: "", payor_cpt_status: {:ok, payor_procedure}}}
  end

  test "Parse Exclusion General CSV, validate/1 method scenario2" do
    #### not existing diagnosis code    #### correct cpt code
    params = %{"Diagnosis Code" => "r23h9", "Payor CPT Code" => "S2196"}

    {:ok, result} = ExclusionGeneralParser.validate(params)
    {:ok, payor_procedure} = result.payor_cpt_status
    {:error, diagnosis} = result.diagnosis_status
    assert {:ok, result} == {:ok, %{diagnosis_status: {:error, diagnosis}, payor_cpt_status: {:ok, payor_procedure}}}
  end

  test "Parse Exclusion General CSV, validate/1 method scenario3" do
    #### valid diagnosis code    #### cpt code not existing
    params = %{"Diagnosis Code" => "A05.0", "Payor CPT Code" => "r23ho"}

    {:ok, result} = ExclusionGeneralParser.validate(params)
    {:error, payor_procedure} = result.payor_cpt_status
    {:ok, diagnosis} = result.diagnosis_status
    assert {:ok, result} == {:ok, %{diagnosis_status: {:ok, diagnosis}, payor_cpt_status: {:error, payor_procedure}}}
  end

  test "Parse Exclusion General CSV, validate/1 method scenario4" do
    #### both blank params
    params = %{"Diagnosis Code" => "", "Payor CPT Code" => ""}

    {:ok, result} = ExclusionGeneralParser.validate(params)
    assert {:ok, result} == {:ok, %{diagnosis_status: "", payor_cpt_status: ""}}
  end

  test "Parse Exclusion General CSV, validate/1 method scenario5" do
    #### both valid params
    params = %{"Diagnosis Code" => "A05.0", "Payor CPT Code" => "LAB0503004"}

    {:ok, result} = ExclusionGeneralParser.validate(params)
    {:ok, payor_procedure} = result.payor_cpt_status
    {:ok, diagnosis} = result.diagnosis_status
    assert {:ok, result} == {:ok, %{diagnosis_status: {:ok, diagnosis}, payor_cpt_status: {:ok, payor_procedure}}}
  end

  test "Parse Exclusion General CSV, validate/1 method scenario6" do
    #### correct diagnosis code        #### blank cpt code
    params = %{"Diagnosis Code" => "A05.0", "Payor CPT Code" => ""}

    {:ok, result} = ExclusionGeneralParser.validate(params)
    {:ok, diagnosis} = result.diagnosis_status
    assert {:ok, result} == {:ok, %{diagnosis_status: {:ok, diagnosis}, payor_cpt_status: ""}}
  end

  test "Parse Exclusion General CSV, validate/1 method scenario7" do
    #### diagnosis code already tagged! as pre-exising        #### cpt code already tagged! as general exclusion
    params = %{"Diagnosis Code" => "A02.2", "Payor CPT Code" => "LAB6764"}

    {:ok, result} = ExclusionGeneralParser.validate(params)
    assert {:ok, result} == {:ok,
      %{
        diagnosis_status: {:error, "Diagnosis is already tagged as Pre-existing condition"},
        payor_cpt_status: {:error, "Payor Procedure is already tagged as General Exclusion"}
      }
    }
  end

end
