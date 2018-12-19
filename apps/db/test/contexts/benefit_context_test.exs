defmodule Innerpeace.Db.Base.BenefitContextTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.{
    Benefit,
    BenefitLimit
  }
  alias Innerpeace.Db.Base.{
    BenefitContext,
    PackageContext
  }

  alias Ecto.UUID

  test "get_all_benefits/0 returns all benefits" do
    benefit =
      :benefit
      |> insert()
      |> Repo.preload([
        :benefit_coverages,
        :created_by,
        :updated_by,
        :benefit_limits,
        benefit_procedures: :procedure,
        benefit_ruvs: :ruv,
        benefit_packages: :package
      ])
    assert BenefitContext.get_all_benefits() == [benefit]
  end

  test "get_benefit/1 returns the benefit with given id" do
    benefit =
      :benefit
      |> insert()
      |> Repo.preload([
        :benefit_limits,
        :benefit_logs,
        :product_benefits,
        benefit_coverages: :coverage,
        benefit_procedures: :procedure,
        benefit_diagnoses: :diagnosis,
        benefit_ruvs: :ruv,
        benefit_packages: :package,
        benefit_pharmacies: :pharmacy,
        benefit_miscellaneous: :miscellaneous
      ])
    assert BenefitContext.get_benefit(benefit.id) == benefit
  end

  test "create_benefit_health/1 creates health benefit with valid attributes" do
    benefit_params = %{
      name: "some content",
      code: "some code",
      category: "Health",
      limit_amount: 123,
      coverage_ids: [UUID.generate()]
    }
    assert {:ok, %Benefit{} = benefit} = BenefitContext.create_benefit_health(benefit_params)
    assert benefit.name == "some content"
  end

  test "create_benefit_health/1 creates health benefit using invalid attributes returns errors" do
    benefit_params = %{}
    assert {:error, changeset} = BenefitContext.create_benefit_health(benefit_params)
    refute Enum.empty?(changeset.errors)
  end

  test "create_benefit_riders/1 creates riders benefit with valid attributes" do
    benefit_params = %{
      name: "some content",
      code: "some code",
      category: "Riders",
      limit_amount: 123,
      coverage_ids: [UUID.generate()]
    }
    assert {:ok, %Benefit{} = benefit} = BenefitContext.create_benefit_riders(benefit_params)
    assert benefit.name == "some content"
  end

  test "create_benefit_riders/1 creates riders benefit using invalid attributes returns errors" do
    benefit_params = %{}
    assert {:error, changeset} = BenefitContext.create_benefit_riders(benefit_params)
    refute Enum.empty?(changeset.errors)
  end

  test "update_benefit_health/2 updates benefit with valid attributes" do
    benefit = insert(:benefit)
    benefit_params = %{
      name: "updated benefit",
      code: "updated code",
      category: "health",
      limit_amount: 123,
      coverage_ids: [UUID.generate()],
      type: "Availment"
    }
    assert {:ok, %Benefit{} = updated_benefit} = BenefitContext.update_benefit_health(benefit, benefit_params)
    assert updated_benefit.name == "updated benefit"
  end

  test "update_benefit_health/2 does not update benefit with invalid attributes" do
    benefit = insert(:benefit)
    benefit_params = %{
      name: "",
      code: ""
    }
    assert {:error, changeset} = BenefitContext.update_benefit_health(benefit, benefit_params)
    refute Enum.empty?(changeset.errors)
  end

  test "update_benefit_riders/2 updates benefit with valid attributes" do
    benefit = insert(:benefit)
    benefit_params = %{
      name: "updated benefit",
      code: "updated code",
      category: "health",
      limit_amount: 123,
      coverage_ids: [UUID.generate()],
      type: "Availment"
    }
    assert {:ok, %Benefit{} = updated_benefit} = BenefitContext.update_benefit_riders(benefit, benefit_params)
    assert updated_benefit.name == "updated benefit"
  end

  test "update_benefit_riders/2 does not update benefit with invalid attributes" do
    benefit = insert(:benefit)
    benefit_params = %{
      name: "",
      code: ""
    }
    assert {:error, changeset} = BenefitContext.update_benefit_riders(benefit, benefit_params)
    refute Enum.empty?(changeset.errors)
  end

  test "update_benefit/1 updates current step" do
    benefit = insert(:benefit)
    user = insert(:user)
    benefit_params = %{
      step: "2",
      updated_by_id: user.id
    }
    assert {:ok, %Benefit{} = updated_benefit} = BenefitContext.update_benefit(benefit, benefit_params)
    assert updated_benefit.step == 2
  end

  test "delete_benefit/1 deletes the benefit" do
    benefit = insert(:benefit)
    assert {:ok, %Benefit{}} = BenefitContext.delete_benefit(benefit.id)
    assert_raise Ecto.NoResultsError, fn -> BenefitContext.get_benefit(benefit.id) end
  end

  test "set_benefit_coverages/2 sets coverages of the given benefit" do
    benefit = insert(:benefit)
    coverage = insert(:coverage)
    BenefitContext.set_benefit_coverages(benefit.id, [coverage.id])
    refute Enum.empty?(BenefitContext.get_benefit(benefit.id).benefit_coverages)
  end

  test "clear_benefit_coverages/1 deletes all coverages of the given benefit" do
    benefit = insert(:benefit)
    coverage = insert(:coverage)
    insert(:benefit_coverage, benefit: benefit, coverage: coverage)
    BenefitContext.clear_benefit_coverages(benefit.id)
    assert Enum.empty?(BenefitContext.get_benefit(benefit.id).benefit_coverages)
  end

  test "set_benefit_procedures/2 sets procedures of the given benefit" do
    benefit = insert(:benefit)
    procedure = insert(:payor_procedure)
    BenefitContext.set_benefit_procedures(benefit.id, [procedure.id])
    refute Enum.empty?(BenefitContext.get_benefit(benefit.id).benefit_procedures)
  end

  test "clear_benefit_procedures/1 deletes all procedures of the given benefit" do
    benefit = insert(:benefit)
    procedure = insert(:payor_procedure)
    insert(:benefit_procedure, benefit: benefit, procedure: procedure)
    BenefitContext.clear_benefit_procedures(benefit.id)
    assert Enum.empty?(BenefitContext.get_benefit(benefit.id).benefit_procedures)
  end

  test "set_benefit_diagnoses/2 sets diagnoses of the given benefit" do
    benefit = insert(:benefit)
    diagnosis = insert(:diagnosis)
    BenefitContext.set_benefit_diagnoses(benefit.id, [diagnosis.id])
    refute Enum.empty?(BenefitContext.get_benefit(benefit.id).benefit_diagnoses)
  end

  test "clear_benefit_diagnoses/1 deletes all diagnoses of the given benefit" do
    benefit = insert(:benefit)
    diagnosis = insert(:diagnosis)
    insert(:benefit_diagnosis, benefit: benefit, diagnosis: diagnosis)
    BenefitContext.clear_benefit_diagnoses(benefit.id)
    assert Enum.empty?(BenefitContext.get_benefit(benefit.id).benefit_diagnoses)
  end

  test "set_benefit_ruvs/2 sets ruvs of the given benefit" do
    benefit = insert(:benefit)
    ruv = insert(:ruv)
    BenefitContext.set_benefit_ruvs(benefit.id, [ruv.id])
    refute Enum.empty?(BenefitContext.get_benefit(benefit.id).benefit_ruvs)
  end

  test "clear_benefit_ruvs/1 deletes all ruvs of the given benefit" do
    benefit = insert(:benefit)
    ruv = insert(:ruv)
    insert(:benefit_ruv, benefit: benefit, ruv: ruv)
    BenefitContext.clear_benefit_ruvs(benefit.id)
    assert Enum.empty?(BenefitContext.get_benefit(benefit.id).benefit_ruvs)
  end

  # test "set_benefit_packages/2 sets packages of the given benefit" do
  #   benefit_package = insert(:benefit_package)
  #   BenefitContext.set_benefit_packages(benefit_package.benefit_id, [benefit_package.package_id])
  #   refute Enum.empty?(BenefitContext.get_benefit(benefit_package.benefit_id).benefit_packages)
  # end

  test "acu_coverage?/1 returns true if benefit coverage is acu" do
    benefit = insert(:benefit)
    coverage = insert(:coverage, %{name: "ACU"})
    insert(:benefit_coverage, benefit: benefit, coverage: coverage)
    assert BenefitContext.acu_coverage?(BenefitContext.get_benefit(benefit.id).benefit_coverages)
  end

  test "acu_coverage?/1 returns false if benefit coverages does not contain ACU" do
    benefit = insert(:benefit)
    coverage = insert(:coverage)
    insert(:benefit_coverage, benefit: benefit, coverage: coverage)
    refute BenefitContext.acu_coverage?(BenefitContext.get_benefit(benefit.id).benefit_coverages)
  end

  test "insert_acu_procedure/2 sets procedures with valid attributes for benefit with ACU coverage" do
    benefit = insert(:benefit)
    procedure = insert(:procedure)
    payor_procedure = insert(:payor_procedure, procedure: procedure)
    package = insert(:package)
    insert(
      :package_payor_procedure,
      package: package,
      payor_procedure: payor_procedure,
      age_from: 1,
      age_to: 5,
      male: true,
      female: true
    )
    package = PackageContext.get_package(package.id)
    BenefitContext.insert_acu_procedure(benefit.id, package.id, package.package_payor_procedure)
    benefit = BenefitContext.get_benefit(benefit.id)
    refute Enum.empty?(benefit.benefit_procedures)
  end

  test "clear_benefit_limits/1 clears benefit coverage limits" do
    benefit = insert(:benefit)
    insert(:benefit_limit, benefit: benefit)
    BenefitContext.clear_benefit_limits(benefit.id)
    assert Enum.empty?(BenefitContext.get_benefit(benefit.id).benefit_limits)
  end

  test "update_benefit_limit/2 updates benefit limit" do
    benefit = insert(:benefit)
    benefit_limit = insert(:benefit_limit, benefit: benefit)
    params = %{
      "benefit_limit_id" => benefit_limit.id,
      "amount" => "123",
      "coverages" => "IP",
      "limit_type" => "Peso"
    }
    assert {:ok, %BenefitLimit{}} = BenefitContext.update_benefit_limit(benefit_limit.id, params)
  end

  test "delete_benefit_limit/1 deletes benefit limit using given id" do
    benefit_limit = insert(:benefit_limit)
    benefit = BenefitContext.get_benefit(benefit_limit.benefit_id)
    refute Enum.empty?(benefit.benefit_limits)
    BenefitContext.delete_benefit_limit(benefit_limit.id)
    benefit = BenefitContext.get_benefit(benefit_limit.benefit_id)
    assert Enum.empty?(benefit.benefit_limits)
  end

  test "setup_limits_params/1 assigns proper params for given limit type" do
    params = %{"coverages" => ["ACU"], "limit_type" => "Peso", "amount" => "123"}
    assert Map.has_key?(BenefitContext.setup_limits_params(params), "limit_amount")
    # params = %{"coverages" => ["ACU"], "limit_type" => "Sessions", "amount" => "123"}
    # assert Map.has_key?(BenefitContext.setup_limits_params(params), "limit_session")
    params = %{"coverages" => ["OPC"], "limit_type" => "Plan Limit Percentage", "amount" => "123"}
    assert Map.has_key?(BenefitContext.setup_limits_params(params), "limit_percentage")
  end

  test "delete_benefit_procedure!/1 deletes benefit procedure by benefit and procedure id" do
    benefit_procedure = insert(:benefit_procedure)
    benefit = BenefitContext.get_benefit(benefit_procedure.benefit_id)
    refute Enum.empty?(benefit.benefit_procedures)
    BenefitContext.delete_benefit_procedure!(benefit_procedure.id)
    benefit = BenefitContext.get_benefit(benefit_procedure.benefit_id)
    assert Enum.empty?(benefit.benefit_procedures)
  end

  test "delete_benefit_disease!/1 deletes benefit disease by benefit and disease id" do
    benefit_disease = insert(:benefit_diagnosis)
    benefit = BenefitContext.get_benefit(benefit_disease.benefit_id)
    refute Enum.empty?(benefit.benefit_diagnoses)
    BenefitContext.delete_benefit_disease!(benefit_disease.id)
    benefit = BenefitContext.get_benefit(benefit_disease.benefit_id)
    assert Enum.empty?(benefit.benefit_diagnoses)
  end

  test "delete_benefit_ruv!/1 deletes benefit ruv by benefit and ruv id" do
    benefit_ruv = insert(:benefit_ruv)
    benefit = BenefitContext.get_benefit(benefit_ruv.benefit_id)
    refute Enum.empty?(benefit.benefit_ruvs)
    BenefitContext.delete_benefit_ruv!(benefit_ruv.id)
    benefit = BenefitContext.get_benefit(benefit_ruv.benefit_id)
    assert Enum.empty?(benefit.benefit_ruvs)
  end

  test "delete_benefit_package!/1 deletes benefit package by benefit and package id" do
    benefit_package = insert(:benefit_package)
    benefit = BenefitContext.get_benefit(benefit_package.benefit_id)
    refute Enum.empty?(benefit.benefit_packages)
    BenefitContext.delete_benefit_package!(benefit_package.id)
    benefit = BenefitContext.get_benefit(benefit_package.benefit_id)
    assert Enum.empty?(benefit.benefit_packages)
  end

  test "set_acu_limit/1 sets acu limit of given benefit" do
    benefit = insert(:benefit)
    BenefitContext.set_acu_limit(benefit.id)
    benefit = BenefitContext.get_benefit(benefit.id)
    refute Enum.empty?(benefit.benefit_limits)
  end

  test "download_benefits with valid data" do
    insert(:user)
    coverage = insert(:coverage)
    benefit = insert(:benefit)
    insert(:benefit_coverage, benefit: benefit, coverage: coverage)
    params = %{code: "benefit_code", name: "benefit_name"}
    result = BenefitContext.download_benefits(params)
    _csv_content = [['Code', 'Name', 'Created BY', 'Date Created', 'Updated By', 'Date Updated', 'Coverages']] ++ result
                  |> CSV.encode
                  |> Enum.to_list
                  |> to_string
    assert _csv_content = BenefitContext.download_benefits(params)
  end

  test "edit_benefit_limit/update benefit record" do
    benefit = insert(:benefit)
    benefit_params = %{
      "name" => "updated benefit_record",
      "code" => "updated code",
      "category" => "health",
      "limits" => ["Inpatient&Peso&5000 PHP&Per Coverage Period"],
      "coverage_ids" => "e6962c84-2633-49bc-ac71-e0cd5c4750bf",
      "coverage_name" => "Inpatient",
      "package_ids" => [UUID.generate()],
      "step" => 1,
      "updated_by_id" => [UUID.generate()]
    }
    assert BenefitContext.update_benefit_record(benefit, benefit_params)
  end

end
