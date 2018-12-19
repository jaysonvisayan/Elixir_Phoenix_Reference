defmodule Innerpeace.Db.Base.Api.ExclusionContextTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Base.Api.{
    ExclusionContext
  }

  alias Innerpeace.Db.Schemas.{
    ExclusionDisease,
    ExclusionCondition,
    ExclusionProcedure
  }

  test "api search_all_exclusions/0, getting all exclusions" do
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

    results = ExclusionContext.search_all_exclusions()

    results = for result <- results do
      %{code: result.code, name: result.name}
    end

    exclusion = %{
      name: exclusion.name,
      code: exclusion.code,
    }

    exclusion2 = %{
      name: exclusion2.name,
      code: exclusion2.code,
    }

    assert results == [exclusion, exclusion2]
  end

  test "api search_exclusion/1, it filters search returning based on the given params" do
    exclusion = insert(:exclusion, name: "general-exclusion101", code: "genex-101")
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
    _exclusion2 = Innerpeace.Db.Base.ExclusionContext.get_exclusion(exclusion2.id)

    params = %{
      "exclusion" => "general-exclusion101"
    }

    results = ExclusionContext.search_exclusion(params)
    results = for result <- results do
      %{code: result.code, name: result.name}
    end

    exclusion = %{
      name: exclusion.name,
      code: exclusion.code,
    }

    # exclusion2 = %{
    #   name: exclusion2.name,
    #   code: exclusion2.code,
    # }

    assert [exclusion] == results
  end

  test "validate_insert/2, inserts an exclusion record. Batch Upload with valid parameters" do
    user = insert(:user)
    procedure = insert(:payor_procedure, code: "P123")
    disease = insert(:diagnosis, code: "D123")

    params = %{
      "coverage" => "General",
      "disease" => [disease.code],
      "procedure" => [procedure.code]
    }

    {coverage, result} = ExclusionContext.validate_general_insert(user, params)

    result_procedure = List.first(result.procedure)
    result_disease = List.first(result.disease)

    assert coverage == :genex
    assert result_procedure.id == procedure.id
    assert result_disease.id == disease.id
  end

  test "validate_insert/2, inserts an exclusion record. Batch Upload with invalid parameters" do
    user = insert(:user)

    params = %{
      "coverage" => "General",
      "disease" => ["test"],
      "procedure" => ["test"]
    }

    {result, changeset} = ExclusionContext.validate_general_insert(user, params)

    assert result == :error
    assert List.first(changeset.changes[:disease]) == "test"
    assert List.first(changeset.changes[:procedure]) == "test"
  end

  test "validate_insert/2, inserts an exclusion record. Pre-existing Condition with valid parameters" do
    user = insert(:user)
    disease = insert(:diagnosis, code: "D123", exclusion_type: "Pre-existing condition", type: "Dreaded")

    duration = %{
      "disease_type" => "Dreaded",
      "duration" => "100",
      "covered_after_duration" => "Percentage",
      "value" => "50"
    }

    params = %{
      "coverage" => "Pre-existing Condition",
      "code" => "PRECON101",
      "name" => "Sample Pre-existing Condition",
      "duration" => [duration],
      "disease" => [disease.code]
    }

    {coverage, exclusion} = ExclusionContext.validate_custom_insert(user, params)

    assert coverage == :precon
    assert exclusion.code == params["code"]
    assert exclusion.name == params["name"]
  end

  test "validate_insert/2, inserts an exclusion record. Pre-existing Condition with invalid parameters" do
    user = insert(:user)
    disease = insert(:diagnosis, code: "D123")

    duration = %{
      "disease_type" => "Dreaded",
      "duration" => "100",
      "percentage" => "100"
    }

    params = %{
      "coverage" => "Pre-existing Condition",
      "code" => "PRECON101",
      "name" => "Sample Pre-existing Condition",
      "duration" => [duration],
      "disease" => [disease.code]
    }

    {result, changeset} = ExclusionContext.validate_custom_insert(user, params)

    assert result == :error
    assert List.first(changeset.changes[:disease]) == "D123"
  end

  test "validate_insert/2, inserts an exclusion record. General Exclusion with valid parameters" do
    user = insert(:user)
    procedure = insert(:payor_procedure, code: "P123", exclusion_type: "General Exclusion")
    disease = insert(:diagnosis, code: "D123", exclusion_type: "General Exclusion")

    params = %{
      "coverage" => "General Exclusion",
      "code" => "genex101",
      "name" => "Sample General Exclusion",
      "procedure" => [procedure.code],
      "disease" => [disease.code]
    }

    {coverage, exclusion} = ExclusionContext.validate_custom_insert(user, params)

    assert coverage == :ge
    assert exclusion.code == params["code"]
    assert exclusion.name == params["name"]
  end

  test "validate_insert/2, inserts an exclusion record. General Exclusion with invalid parameters" do
    user = insert(:user)

    params = %{
      "coverage" => "General Exclusion",
      "code" => "genex101",
      "name" => "Sample General Exclusion",
      "procedure" => ["test"],
      "disease" => ["test"]
    }

    {coverage, _exclusion} = ExclusionContext.validate_custom_insert(user, params)

    assert coverage == :error
  end

  describe "create_pre_existing" do
    test "with invalid parameters" do
      user = insert(:user)
      params = %{
        code: "test_pre_ex"
      }
      assert {:error, changeset} = ExclusionContext.create_pre_existing(params, user)
      refute changeset.valid?
    end

    test "with valid parameters" do
      user = insert(:user)
      diagnosis = insert(:diagnosis, code: "['A00.0']")
      params = %{
        code: "TEST_PRE_EX_1",
        name: "TEST_PRE_EX_1",
        conditions: [
          %{
            "member_type": "Dependent",
            "diagnosis_type": "Dreaded",
            "limit_type": "Percentage",
            "limit_amount": "100",
            "duration": 234,
            "within_grace_period": "false"
          },
          %{
            "member_type": "Dependent",
            "diagnosis_type": "Dreaded",
            "limit_type": "Peso",
            "limit_amount": "100000.212",
            "duration": 23,
            "within_grace_period": "true"
          }
        ],
        diagnosis: [diagnosis.code]
      }
      assert {:ok, exclusion} = ExclusionContext.create_pre_existing(params, user)
      assert exclusion.code == "TEST_PRE_EX_1"
      assert exclusion.name == "TEST_PRE_EX_1"
    end
  end

  describe "insert_diagnoses/2" do
    test "with valid parameters" do
      exclusion = insert(:exclusion)
      diagnosis = insert(:diagnosis)
      assert {
        :ok,
        [%ExclusionDisease{} = exclusion_diagnosis]
      } = ExclusionContext.insert_diagnoses(exclusion, [diagnosis.id])
      assert exclusion_diagnosis.exclusion_id == exclusion.id
      assert exclusion_diagnosis.disease_id == diagnosis.id
    end

    test "with invalid parameters" do
      exclusion = insert(:exclusion)
      random_uuid = Ecto.UUID.generate()
      assert_raise Ecto.ConstraintError, fn ->
        ExclusionContext.insert_diagnoses(exclusion, [random_uuid])
      end
    end
  end

  describe "insert_conditions/2" do
    test "with valid parameters" do
      exclusion = insert(:exclusion)
      params = %{
        "member_type" => "Principal",
        "diagnosis_type" => "Dreaded",
        "duration" => "12",
        "limit_type" => "Peso",
        "limit_amount" => "1500.50",
        "within_grace_period" => "true"
      }
      assert {
        :ok,
        [%ExclusionCondition{} = exclusion_condition]
      } = ExclusionContext.insert_conditions(exclusion, [params])
      assert exclusion_condition.member_type == params["member_type"]
      assert exclusion_condition.diagnosis_type == params["diagnosis_type"]
    end

    test "with invalid parameters" do
      exclusion = insert(:exclusion)
      params = %{
        "member_type" => "test",
        "diagnosis_type" => "test",
        "duration" => "asdf",
        "limit_type" => "sample",
        "limit_amount" => "test",
        "within_grace_period" => "true"
      }
      assert_raise Ecto.InvalidChangesetError, fn ->
        ExclusionContext.insert_conditions(exclusion, [params])
      end
    end
  end

  describe "insert_procedures/2" do
    test "with valid parameters" do
      procedure = insert(:procedure)
      payor_procedure = insert(:payor_procedure, procedure: procedure)
      exclusion = insert(:exclusion)
      assert {
        :ok,
        [%ExclusionProcedure{} = exclusion_procedure]
      } = ExclusionContext.insert_procedures(exclusion, [payor_procedure.id])
      assert exclusion_procedure.exclusion_id == exclusion.id
      assert exclusion_procedure.procedure_id == payor_procedure.id
    end
  end

  describe "create_exclusion" do
    test "with invalid parameters" do
      user = insert(:user)
      params = %{
        code: "test_pre_ex"
      }
      assert {:error, changeset} = ExclusionContext.create_exclusion(params, user)
      refute changeset.valid?
    end

    test "with valid parameters (Policy)" do
      user = insert(:user)
      params = %{
        code: "test_exclusion",
        name: "test_exclusion",
        type: "Policy",
        classification_type: "stAndArD",
        policy: ["TEST POLICY HELLO HI HAHAHAHAHAHAHAHAHA"]
      }
      assert {:ok, exclusion} = ExclusionContext.create_exclusion(params, user)
      assert exclusion.code == params.code
      assert exclusion.name == params.name
      assert exclusion.type == params.type
      assert exclusion.classification_type == "Standard"
      assert exclusion.policy == params.policy
    end

    test "with valid parameters (ICD/CPT Based)" do
      user = insert(:user)
      diagnosis = insert(:diagnosis, code: "ADIAOWHISKEY <3")
      procedure = insert(:procedure)
      payor_procedure = insert(:payor_procedure, procedure: procedure, code: "HIHI")
      params = %{
        code: "test_exclusion",
        name: "test_exclusion",
        type: "ICD/CPT Based",
        classification_type: "stAndArD",
        diagnoses: [diagnosis.code],
        procedures: [payor_procedure.code]
      }
      assert {:ok, exclusion} = ExclusionContext.create_exclusion(params, user)
      assert exclusion.code == params.code
      assert exclusion.name == params.name
      assert exclusion.type == params.type
      assert exclusion.classification_type == "Standard"
      assert is_nil(exclusion.policy)
    end
  end

end

