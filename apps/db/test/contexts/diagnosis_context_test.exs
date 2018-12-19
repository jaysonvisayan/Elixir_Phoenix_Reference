defmodule Innerpeace.Db.Base.DiagnosisContextTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.{
    Diagnosis
    # DiagnosisCoverage,
    # Coverage
  }
  alias Innerpeace.Db.Base.{
    DiagnosisContext
  }
  alias Innerpeace.Db.Repo

  # @invalid_attrs %{}

  test "list all diagnoses" do
    diagnosis = insert(:diagnosis)
    insert(:diagnosis_coverage)
    assert DiagnosisContext.get_all_diagnoses() == [diagnosis] |> Repo.preload([diagnosis_coverages: :coverage])
  end

  test "get_diagnosis returns the diagnosis with given id" do
    diagnosis = insert(:diagnosis)
    assert DiagnosisContext.get_diagnosis(diagnosis.id) == diagnosis
  end

  test "csv_params gets the model for export" do
    insert(:diagnosis)
    insert(:coverage)
    insert(:diagnosis_coverage)
    params = %{model: "Diagnosis"}
    diagnoses =
      Diagnosis
      |> select([d], [d.code, d.description, d.group_description, d.type, d.congenital, d.exclusion_type])
      |> order_by([d], asc: d.code)
      |> Repo.all
    diagnosis2 = DiagnosisContext.get_all_diagnoses
    coverages = for diagnosis <- diagnosis2 do
      for dc <- diagnosis.diagnosis_coverages do
        dc.coverage.name
      end
    end
    coverage_diagnosis = for diagnoses <- diagnoses do
      for coverage <- coverages do
         cove =
          coverage
          |> Enum.sort()
          |> Enum.join(", ")
        _diagnoses = diagnoses ++ [cove]
      end
    end
    diagnoses = Enum.at(coverage_diagnosis, 0)
    csv_content = [['Code', 'Description', 'Group Description', 'Type', 'Congenital', 'Exclusion Type', 'Coverage']] ++ diagnoses
                  |> CSV.encode
                  |> Enum.to_list
                  |> to_string
    assert DiagnosisContext.csv_params(params.model) == csv_content
  end

  test "create_update_diagnosis_log with changes" do
    diagnosis = insert(:diagnosis, exclusion_type: "General Exclusion")
    user = insert(:user)
    params = %{
      exclusion_type: ""
    }

    result = DiagnosisContext.create_update_diagnosis_log(user, Diagnosis.changeset(diagnosis, params))

    assert result.diagnosis_id == diagnosis.id
  end

  test "create_update_diagnosis_log without changes" do
    diagnosis = insert(:diagnosis, exclusion_type: "General Exclusion")
    user = insert(:user)
    params = %{
      exclusion_type: "General Exclusion"
    }

    result = DiagnosisContext.create_update_diagnosis_log(user, Diagnosis.changeset(diagnosis, params))

    assert result == nil
  end

  test "get_logs with valid diagnosis id" do
    diagnosis = insert(:diagnosis, exclusion_type: "General Exclusion")
    user = insert(:user)
    insert(:diagnosis_log, diagnosis: diagnosis, user: user)

    result = DiagnosisContext.get_logs(diagnosis.id)

    assert length(result) > 0
  end

  test "get_logs with invalid diagnosis id" do
    diagnosis = insert(:diagnosis, exclusion_type: "General Exclusion")
    user = insert(:user)
    insert(:diagnosis_log, diagnosis: diagnosis, user: user)
    {_, id} = Ecto.UUID.load(Ecto.UUID.bingenerate)

    result = DiagnosisContext.get_logs(id)

    assert length(result) == 0
  end
end
