defmodule Innerpeace.Db.Base.ExclusionContextTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.{
    Exclusion
    # ExclusionDisease,
    # ExclusionProcedure
  }
  alias Innerpeace.Db.Base.{
    ExclusionContext
  }

  test "get_all_exclusions/0 returns all exclusion" do
    exclusion =
      :exclusion
      |> insert()
      |> Repo.preload([
        :created_by,
        :updated_by,
        :exclusion_durations,
        exclusion_diseases: :disease,
        exclusion_procedures: :procedure
      ])
    assert ExclusionContext.get_all_exclusions() == [exclusion]
  end

  test "get_exclusion/1 returns the exclusion with given id" do
    exclusion =
      :exclusion
      |> insert()
      |> Repo.preload([
        :created_by,
        :updated_by,
        :exclusion_durations,
        exclusion_procedures: :procedure,
        exclusion_diseases: :disease,
      ])
    assert ExclusionContext.get_exclusion(exclusion.id) == exclusion
  end

  test "create_exclusion/1 creates General Exclusion with valid attributes" do
    exclusion_params = %{
      name: "some content",
      code: "some code",
      coverage: "General Exclusion",
    }
    assert {:ok, %Exclusion{} = exclusion} = ExclusionContext.create_exclusion(exclusion_params)
    assert exclusion.name == "some content"
  end

  test "create_exclusion/1 creates General Exclusion using invalid attributes returns errors" do
    exclusion_params = %{}
    assert {:error, changeset} = ExclusionContext.create_exclusion(exclusion_params)
    refute Enum.empty?(changeset.errors)
  end

  test "create_pre_existing/1 creates an exclusion with exclusion coverage Pre-existing Condition with valid attributes" do
    exclusion_params = %{
      name: "some content",
      code: "some code",
      coverage: "Pre-existing Condition",
      limit_type: "Peso"
    }
    assert {:ok, %Exclusion{} = exclusion} = ExclusionContext.create_pre_existing(exclusion_params)
    assert exclusion.name == "some content"
  end

  test "create_pre_existing/1 creates Pre-existing Condition using invalid attributes returns errors" do
    exclusion_params = %{}
    assert {:error, changeset} = ExclusionContext.create_pre_existing(exclusion_params)
    refute Enum.empty?(changeset.errors)
  end

  test "update_exclusion/2 updates General Exclusion with valid attributes" do
    exclusion = insert(:exclusion)
    exclusion_params = %{
      name: "updated exclusion",
      code: "updated code",
      coverage: "General Exclusion"
    }
    assert {:ok, %Exclusion{} = updated_exclusion} = ExclusionContext.update_exclusion(exclusion, exclusion_params)
    assert updated_exclusion.name == "updated exclusion"
  end

  test "update_exclusion/2 does not update General Exclusuion exclusion with invalid attributes" do
    exclusion = insert(:exclusion)
    exclusion_params = %{
      name: "",
      code: "",
      coverage: "General Exclusion"
    }
    assert {:error, changeset} = ExclusionContext.update_exclusion(exclusion, exclusion_params)
    refute Enum.empty?(changeset.errors)
  end

  test "update_pre_existing/2 updates Pre-existing Condition with valid attributes" do
    exclusion = insert(:exclusion)
    exclusion_params = %{
      name: "updated exclusion",
      code: "updated code",
      coverage: "Pre-existing Condition",
      limit_type: "Peso"
    }
    assert {:ok, %Exclusion{} = updated_exclusion} = ExclusionContext.update_pre_existing(exclusion, exclusion_params)
    assert updated_exclusion.name == "updated exclusion"
  end

  test "update_pre_existing/2 does not update Pre-existing Condition with invalid attributes" do
    exclusion = insert(:exclusion)
    exclusion_params = %{
      name: "",
      code: "",
      coverage: "Pre-existing Condition"
    }
    assert {:error, changeset} = ExclusionContext.update_pre_existing(exclusion, exclusion_params)
    refute Enum.empty?(changeset.errors)
  end

  test "update_exclusion/1 updates current step" do
    exclusion = insert(:exclusion)
    user = insert(:user)
    exclusion_params = %{
      step: "2",
      updated_by_id: user.id
    }
    assert {:ok, %Exclusion{} = updated_exclusion} = ExclusionContext.update_exclusion_step(exclusion, exclusion_params)
    assert updated_exclusion.step == 2
  end

  test "delete_exclusion/1 deletes the exclusion" do
    exclusion = insert(:exclusion)
    assert {:ok, %Exclusion{}} = ExclusionContext.delete_exclusion(exclusion.id)
    assert_raise Ecto.NoResultsError, fn -> ExclusionContext.get_exclusion(exclusion.id) end
  end

  test "set_exclusion_procedure/2 sets procedures of the given exclusion" do
    exclusion = insert(:exclusion)
    procedure = insert(:payor_procedure)
    ExclusionContext.set_exclusion_procedure(exclusion.id, [procedure.id])
    refute Enum.empty?(ExclusionContext.get_exclusion(exclusion.id).exclusion_procedures)
  end

  test "clear_exclusion_procedures/1 deletes all procedures of the given exclusion" do
    exclusion = insert(:exclusion)
    procedure = insert(:payor_procedure)
    insert(:exclusion_procedure, exclusion: exclusion, procedure: procedure)
    ExclusionContext.clear_exclusion_procedure(exclusion.id)
    assert Enum.empty?(ExclusionContext.get_exclusion(exclusion.id).exclusion_procedures)
  end

  test "set_exclusion_diseases/2 sets diseases of the given exclusion" do
    exclusion = insert(:exclusion)
    disease = insert(:diagnosis)
    ExclusionContext.set_exclusion_disease(exclusion.id, [disease.id])
    refute Enum.empty?(ExclusionContext.get_exclusion(exclusion.id).exclusion_diseases)
  end

  test "clear_exclusion_diseases/1 deletes all diseases of the given exclusion" do
    exclusion = insert(:exclusion)
    disease = insert(:diagnosis)
    insert(:exclusion_diseases, exclusion: exclusion, disease: disease)
    ExclusionContext.clear_exclusion_disease(exclusion.id)
    assert Enum.empty?(ExclusionContext.get_exclusion(exclusion.id).exclusion_diseases)
  end

  test "set_exclusion_duration/2 sets durations of the given exclusion" do
    exclusion = insert(:exclusion)
     exclusion_params = %{
       "disease_type" => "Dreaded",
       "duration" => 1,
       "covered_after_duration" => "Peso",
       "cad_value" => Decimal.new(1200.50)
    }
    ExclusionContext.create_duration(exclusion.id, exclusion_params)
    refute Enum.empty?(ExclusionContext.get_exclusion(exclusion.id).exclusion_durations)
  end

  test "clear_exclusion_diseases/1 sorts all diseases of the given exclusion with disease type Dreaded" do
    exclusion = insert(:exclusion)
    disease = insert(:diagnosis)
    insert(:exclusion_diseases, exclusion: exclusion, disease: disease)
    ExclusionContext.clear_exclusion_disease_by_diseases_type(exclusion.id, "Dreaded")
    refute Enum.member?(ExclusionContext.get_exclusion(exclusion.id).exclusion_diseases, type: "Non-Dreaded")
  end

  test "clear_exclusion_diseases/1 sorts all diseases of the given exclusion with disease type Non-Dreaded" do
    exclusion_disease = insert(:exclusion_diseases)
    ExclusionContext.clear_exclusion_disease_by_diseases_type(exclusion_disease.exclusion_id, "Non-Dreaded")
    refute Enum.member?(ExclusionContext.get_exclusion(exclusion_disease.exclusion_id).exclusion_diseases, type: "Dreaded")
  end

end
