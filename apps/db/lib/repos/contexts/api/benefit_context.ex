defmodule Innerpeace.Db.Base.Api.BenefitContext do
  @moduledoc false

  alias Innerpeace.Db.{
    Repo,
    Schemas.Benefit,
    Schemas.Coverage,
    Schemas.BenefitCoverage,
    Schemas.BenefitProcedure,
    Schemas.BenefitRUV,
    Schemas.BenefitLimit,
    Schemas.BenefitDiagnosis,
    Schemas.PayorProcedure,
    Schemas.RUV,
    Schemas.Package,
    Schemas.Diagnosis,
    Base.Api.UtilityContext,
    Base.BenefitContext,
    Base.PackageContext,
    Schemas.BenefitPackage
  }
  alias Innerpeace.Db.Base.BenefitContext, as: MainBenefitContext1
  alias Ecto.Changeset
  alias Decimal

  import Ecto.Query

  #API
  def search_benefits(params) do
    Benefit
    |> where([b], fragment("lower(?)", b.code) == fragment("lower(?)", ^params["benefit"]))
    |> Repo.all
    |> Repo.preload([
      :created_by,
      :updated_by,
      :benefit_limits,
      benefit_ruvs: :ruv,
      benefit_coverages: :coverage,
      benefit_diagnoses: :diagnosis,
      benefit_procedures: [
        procedure: [
          procedure: :procedure_category
        ]
      ],
      benefit_packages: :package
    ])
  end

  def get_all_benefit do
    Benefit
    |> Repo.all
    |> Repo.preload([
      :created_by,
      :updated_by,
      :benefit_limits,
      benefit_ruvs: :ruv,
      benefit_coverages: :coverage,
      benefit_diagnoses: :diagnosis,
      benefit_procedures: [
        procedure: [
          procedure: :procedure_category
        ]
      ],
      benefit_packages: :package
    ])
  end

  def create_benefit(current_user, params) do
    current_user =
      if not is_nil(current_user) do
        current_user = current_user.id
      else
        current_user = ""
      end
    params = Map.put(params, "created_by_id", current_user)
    params = Map.put(params, "updated_by_id", current_user)
    params = Map.put(params, "step", 0)
    with {:ok, changeset} <- validate_fields(params),
         {:ok, benefit} <- insert_benefit(changeset.changes),
         {:ok} <- insert_benefit_coverages(benefit.id, Enum.uniq(changeset.changes.coverages)),
         {:ok} <- insert_benefit_procedures(benefit.id, Enum.uniq(params["procedures"] || [])),
         {:ok} <- insert_benefit_diseases(benefit.id, Enum.uniq(params["diseases"] || [])),
         {:ok} <- insert_benefit_ruvs(benefit.id, Enum.uniq(params["ruvs"] || [])),
         {:ok} <- insert_benefit_limits(benefit.id, params["limits"] || []),
         {:ok} <- insert_benefit_package(benefit.id, changeset.changes),
         %Benefit{} = benefit <- BenefitContext.get_benefit(benefit.id)
    do
      {:ok, benefit}
    else
      {:changeset_error, changeset} ->
        # {:error, changeset}
        {:error, UtilityContext.changeset_errors_to_string(changeset.errors)}
      _ ->
        {:error, "Error has been occurred."}
    end
  end

  def create_benefit(current_user, params, nil), do: {:error_type}

  def create_benefit(current_user, params, "Availment") do
    params = benefit_transform_params(current_user, params, "Availment")

    with {:ok, changeset} <- validate_fields_availment(params),
         {:ok, benefit} <- insert_benefit(changeset.changes),
         {:ok} <- insert_benefit_coverages(benefit.id, Enum.uniq(changeset.changes.coverages)),
         {:ok} <- insert_benefit_procedures_v2(params["all_procedure"] || false, benefit.id, Enum.uniq(params["procedures"] || [])),
         {:ok} <- insert_benefit_diseases_v2(params["all_diagnosis"] || false, benefit.id, Enum.uniq(params["diseases"] || [])),
         {:ok} <- insert_benefit_ruvs(benefit.id, Enum.uniq(params["ruvs"] || [])),
         {:ok} <- insert_benefit_limits(benefit.id, params["limits"] || []),
         {:ok} <- insert_benefit_package(benefit.id, changeset.changes),
         %Benefit{} = benefit <- BenefitContext.get_benefit(benefit.id)
    do
      {:ok, benefit}
    else
      {:changeset_error, changeset} ->
        # {:error, changeset}
        {:error, UtilityContext.changeset_errors_to_string(changeset.errors)}
    end
  end

  defp benefit_transform_params(current_user, params, "Availment") do
    current_user = if is_nil(current_user), do: "", else: current_user.id
    all_procedure = convert_string_to_boolean(params["all_procedures"])
    all_diagnosis = convert_string_to_boolean(params["all_diagnoses"])
    loa_facilitated = convert_string_to_boolean(params["loa_facilitated"])
    reimbursement = convert_string_to_boolean(params["reimbursement"])
    classification = String.capitalize("#{params["classification"]}")
    params
    |> Map.put("created_by_id", current_user)
    |> Map.put("updated_by_id", current_user)
    |> Map.put("step", 0)
    |> Map.replace("type", "Availment")
    |> Map.put("all_procedure", all_procedure)
    |> Map.put("all_diagnosis", all_diagnosis)
    |> Map.replace("classification", classification)
    |> Map.replace("loa_facilitated", loa_facilitated)
    |> Map.replace("reimbursement", reimbursement)
  end

  defp benefit_transform_params(current_user, params, "Policy") do
    current_user = if is_nil(current_user), do: "", else: current_user.id
    all_procedure = convert_string_to_boolean(params["all_procedure"])
    all_diagnosis = convert_string_to_boolean(params["all_diagnosis"])
    loa_facilitated = convert_string_to_boolean(params["loa_facilitated"])
    reimbursement = convert_string_to_boolean(params["reimbursement"])
    classification = String.capitalize("#{params["classification"]}")
    params
    |> Map.put("created_by_id", current_user)
    |> Map.put("updated_by_id", current_user)
    |> Map.put("step", 0)
    |> Map.replace("type", "Policy")
    |> Map.replace("all_procedure", all_procedure)
    |> Map.replace("all_diagnosis", all_diagnosis)
    |> Map.replace("classification", classification)
    |> Map.replace("loa_facilitated", loa_facilitated)
    |> Map.replace("reimbursement", reimbursement)
  end

  def create_benefit(current_user, params, "Policy") do
    params = benefit_transform_params(current_user, params, "Policy")

      with {:ok, changeset} <- validate_fields_policy(params),
           {:ok, benefit} <- insert_benefit(changeset.changes),
           {:ok} <- insert_benefit_coverages(benefit.id, Enum.uniq(changeset.changes.coverages)),
           %Benefit{} = benefit <- BenefitContext.get_benefit(benefit.id)
      do
        {:ok, benefit}
      else
        {:changeset_error, changeset} ->
          {:error, changeset}
      end
  end

  def create_benefit(current_user, params, type), do: {:error_type}

  defp insert_benefit_package(benefit_id, params) do
    if Enum.member?(params.coverages, "ACU") do
      # insert_package_procedures(benefit_id, params.packages)
      package_ids = Enum.map(params[:packages] || [], &(get_package_by_code(&1).id))
      BenefitContext.set_benefit_packages(benefit_id, package_ids)
      # BenefitContext.set_acu_limit(benefit_id, params)
    else
      package_ids = Enum.map(params[:packages] || [], &(get_package_by_code(&1).id))
      BenefitContext.set_benefit_packages(benefit_id, package_ids)
    end
    {:ok}
  end

  defp insert_package_procedures(benefit_id, package_codes) do
    for package_code <- package_codes do
      package = get_package_by_code(package_code)
      BenefitContext.insert_acu_procedure(benefit_id, package.id, package.package_payor_procedure)
    end
  end

  defp insert_benefit(params) do
    if params.category == "Health" do
      params = Map.put(params, :coverage_ids, params.coverages)
      changeset = Benefit.changeset_health(%Benefit{}, params)
    else
      changeset = Benefit.changeset_riders(%Benefit{}, params)
    end
    changeset
    |> Repo.insert()
  end

  defp insert_benefit_v2(params) do
    params = Map.put(params, :coverage_ids, params.coverages)
    changeset = Benefit.changeset_acu_policy(%Benefit{}, params)
    changeset
    |> Repo.insert()
  end

  defp insert_benefit_coverages(benefit_id, coverage_codes) do
    for coverage_code <- coverage_codes do
      coverage = get_coverage_data_by_code(coverage_code)
      params = %{benefit_id: benefit_id, coverage_id: coverage.id}

      %BenefitCoverage{}
      |> BenefitCoverage.changeset(params)
      |> Repo.insert()
    end
    {:ok}
  end

  defp insert_benefit_diseases(benefit_id, disease_codes \\ []) do
    for disease_code <- disease_codes do
      disease = get_disease_by_code(disease_code)
      params = %{benefit_id: benefit_id, diagnosis_id: disease.id}

      %BenefitDiagnosis{}
      |> BenefitDiagnosis.changeset(params)
      |> Repo.insert()
    end
    {:ok}
  end

  defp insert_benefit_diseases_v2(false, benefit_id, disease_codes \\ []) do
    for disease_code <- disease_codes do
      disease = get_disease_by_code(disease_code)
      params = %{benefit_id: benefit_id, diagnosis_id: disease.id}

      %BenefitDiagnosis{}
      |> BenefitDiagnosis.changeset(params)
      |> Repo.insert()
    end
    {:ok}
  end
  defp insert_benefit_diseases_v2(params, benefit_id, disease_codes), do: {:ok}

  defp insert_benefit_procedures(benefit_id, procedure_codes \\ []) do
    for procedure_code <- procedure_codes do
      procedure = get_procedure_by_code(procedure_code)
      params = %{benefit_id: benefit_id, procedure_id: procedure.id}

      %BenefitProcedure{}
      |> BenefitProcedure.changeset(params)
      |> Repo.insert()
    end
    {:ok}
  rescue
    _ ->
    {:error}
  end

  defp insert_benefit_procedures_v2(false, benefit_id, procedure_codes \\ []) do
    for procedure_code <- procedure_codes do
      procedure = get_procedure_by_code(procedure_code)
      params = %{benefit_id: benefit_id, procedure_id: procedure.id}

      %BenefitProcedure{}
      |> BenefitProcedure.changeset(params)
      |> Repo.insert()
    end
    {:ok}
  end
  defp insert_benefit_procedures_v2(params, benefit_id, procedure_codes), do: {:ok}

  defp insert_benefit_ruvs(benefit_id, ruv_codes \\ []) do
    for ruv_code <- ruv_codes do
      ruv = get_ruv_by_code(ruv_code)
      params = %{benefit_id: benefit_id, ruv_id: ruv.id}

      %BenefitRUV{}
      |> BenefitRUV.changeset(params)
      |> Repo.insert()
    end
    {:ok}
  end

  defp insert_benefit_limits(benefit_id, limits) do
    for limit <- limits do
      coverages =
        limit["coverages"]
        |> Enum.join(", ")

      if String.contains?(String.downcase(coverages), "peme") do
        if String.downcase(limit["limit_type"]) == "sessions" do
          {:ok}
        else
          insert_valid_benefit_limit(coverages, benefit_id, limit)
        end
      else
        insert_valid_benefit_limit(coverages, benefit_id, limit)
      end
    end
    {:ok}
  end

  defp insert_valid_benefit_limit(coverages, benefit_id, limit) do
    params = %{
      benefit_id: benefit_id,
      coverages: coverages,
      limit_type: limit["limit_type"],
      limit_percentage: limit["limit_percentage"],
      limit_amount: limit["limit_amount"],
      limit_session: limit["limit_session"],
      limit_classification: limit["limit_classification"]
    }

    %BenefitLimit{}
    |> BenefitLimit.changeset(params)
    |> Repo.insert()
  end

  defp validate_fields(params) do
    types = %{
      name: :string,
      code: :string,
      category: :string,
      coverages: {:array, :string},
      maternity_type: :string,
      acu_type: :string,
      acu_coverage: :string,
      provider_access: :string,
      peme: :boolean,
      created_by_id: :binary_id,
      updated_by_id: :binary_id,
      procedures: {:array, :string},
      ruvs: {:array, :string},
      diseases: {:array, :string},
      package: :binary_id,
      limits: {:array, :map},
      step: :integer,
      packages: {:array, :string},
      condition: :string,
      covered_enrollees: :string,
      waiting_period: :string,
      all_diagnosis: :boolean,
      all_procedure: :boolean,
      risk_share_type: :string,
      risk_share_value: :decimal,
      member_pays_handling: {:array, :string}
    }
    changeset =
      {%{}, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([
        :name,
        :code,
        :category,
        :coverages,
        :condition
      ], message: "is required")
      |> Changeset.validate_inclusion(:category, [
        "Riders",
        "Health"
      ], message: "is invalid")
      |> Changeset.validate_inclusion(:package, get_all_package_codes(), message: "is invalid")
      |> Changeset.validate_subset(:diseases, get_all_disease_codes(), message: "requires atleast one valid ICD")
      |> Changeset.validate_subset(:ruvs, get_all_ruv_codes(), message: "is invalid")
      |> Changeset.validate_subset(:procedures, get_all_procedure_codes(), message: "is invalid")
      |> Changeset.validate_subset(:packages, get_all_package_codes(), message: "is invalid")
      |> Changeset.validate_inclusion(:condition, ["ALL", "ANY"], message: "is invalid")
      |> Changeset.validate_inclusion(:risk_share_type, ["None", "none", "Copay", 
                                                         "copay", "Coinsurance", "coinsurance"], message: "is invalid")
      |> Changeset.validate_subset(:member_pays_handling, ["ASO override", "aso override", "Corporate Guarantee", 
                                                           "corporate guarantee", "Ex-Gratia", "ex-gratia", 
                                                           "Fee for Service", "fee for service", "Member pays", "member pays"], message: "is invalid")
      |> validate_risk_share()
      |> validate_coverages()
      |> acu_validations()
      |> maternity_validations()
      |> validate_added_maternity_validation()
      |> validate_code()
      |> validate_procedure_count()
      |> validate_ruv_count()
      |> validate_limits()
      |> validate_acu_limit()
      |> validate_op_consult_diseases()
    if changeset.valid? do
      {:ok, changeset}
    else
      {:changeset_error, changeset}
    end
  end

  defp validate_fields_availment(params) do
    types = %{
      type: :string,
      name: :string,
      code: :string,
      category: :string,
      coverages: {:array, :string},
      maternity_type: :string,
      acu_type: :string,
      acu_coverage: :string,
      provider_access: :string,
      peme: :boolean,
      created_by_id: :binary_id,
      updated_by_id: :binary_id,
      procedures: {:array, :string},
      ruvs: {:array, :string},
      diseases: {:array, :string},
      package: :binary_id,
      limits: {:array, :map},
      step: :integer,
      packages: {:array, :string},
      condition: :string,
      covered_enrollees: :string,
      waiting_period: :string,
      all_diagnosis: :boolean,
      all_procedure: :boolean,
      classification: :string,
      loa_facilitated: :boolean,
      reimbursement: :boolean,
      risk_share_type: :string,
      risk_share_value: :decimal,
      member_pays_handling: {:array, :string}
    }
    changeset =
      {%{}, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([
        :name,
        :code,
        :category,
        :coverages,
        :condition,
        :type
      ], message: "is required")
      |> Changeset.validate_inclusion(:category, [
        "Riders",
        "Health"
      ], message: "is invalid")
      |> Changeset.validate_inclusion(:package, get_all_package_codes(), message: "is invalid")
      |> Changeset.validate_subset(:diseases, get_all_disease_codes(), message: "requires atleast one valid ICD")
      |> Changeset.validate_subset(:ruvs, get_all_ruv_codes(), message: "is invalid")
      |> Changeset.validate_subset(:procedures, get_all_procedure_codes(), message: "is invalid")
      |> Changeset.validate_subset(:packages, get_all_package_codes(), message: "is invalid")
      |> Changeset.validate_inclusion(:condition, ["ALL", "ANY"], message: "is invalid")
      |> Changeset.validate_inclusion(:type, ["Availment", "availment"], message: "is invalid")
      |> Changeset.validate_inclusion(:all_procedure, [true, false], message: "is invalid")
      |> Changeset.validate_inclusion(:classification, ["Standard", "Custom", "standard", "custom"], message: "is invalid")
      |> Changeset.validate_inclusion(:all_diagnosis, [true, false], message: "is invalid")
      |> Changeset.validate_inclusion(:loa_facilitated, [true, false], message: "is invalid")
      |> Changeset.validate_inclusion(:reimbursement, [true, false], message: "is invalid")
      |> Changeset.validate_inclusion(:risk_share_type, ["None", "none", "Copay", 
                                                         "copay", "Coinsurance", "coinsurance"], message: "is invalid")
      |> Changeset.validate_subset(:member_pays_handling, ["ASO override", "aso override", "Corporate Guarantee", 
                                                         "corporate guarantee", "Ex-Gratia", "ex-gratia", 
                                                         "Fee for Service", "fee for service", "Member pays", "member pays"], message: "is invalid")
      |> Changeset.validate_format(:code, ~r/^[a-zA-Z0-9_.-]*$/, message: "has invalid format")
      |> Changeset.validate_length(:code, max: 50, message: "must not exceed 50 characters")
      |> Changeset.validate_length(:name, max: 400, message: "must not exceed 400 characters")
      |> validate_risk_share()
      |> validate_coverages()
      |> acu_validations()
      |> validate_all_procedures()
      |> validate_all_diagnoses()
      |> maternity_validations()
      |> validate_classification()
      |> validate_benefit_availment()
      |> validate_added_maternity_validation()
      |> validate_code()
      |> validate_procedure_count_lvl1()
      |> validate_ruv_count()
      |> validate_limits()
      |> validate_acu_limit()
      |> validate_op_consult_diseases()
      
    if changeset.valid? do
      {:ok, changeset}
    else
      {:changeset_error, changeset}
    end
  end

  defp validate_all_procedures(changeset) do
    with true <- Map.has_key?(changeset.changes, :all_procedure),
         true <- Map.has_key?(changeset.changes, :procedures),
         true <- changeset.changes.all_procedure
    do
      Changeset.add_error(
        changeset,
        :procedures,
        "Invalid Procedure: already selected all_procedures"
      )
    else
      _ ->
        changeset
    end
  end

  defp validate_all_diagnoses(changeset) do
    with true <- Map.has_key?(changeset.changes, :all_diagnosis),
         true <- Map.has_key?(changeset.changes, :diseases),
         true <- changeset.changes.all_diagnosis
    do
      Changeset.add_error(
        changeset,
        :diseases,
        "Invalid Diagnosis: already selected all_diagnoses."
      )
    else
      _ ->
        changeset
    end
  end

  defp validate_availment_or_policy_keys("Availment", changeset) do
    loa_facilitated = if Map.has_key?(changeset.changes, :loa_facilitated),
                         do: changeset.changes.loa_facilitated, else: nil

    reimbursement = if Map.has_key?(changeset.changes, :reimbursement),
                        do: changeset.changes.reimbursement, else: nil

    with true <- is_nil(loa_facilitated) and is_nil(reimbursement) or
                  loa_facilitated == false and reimbursement == false or
                  loa_facilitated == false and is_nil(reimbursement) or
                 is_nil(loa_facilitated) and reimbursement == false
    do
      Changeset.add_error(changeset,
                          :loa_facilitated,
                          "loa_facilitated/reimbursement: Atleast one should be true"
      )
    else
      _ ->
        changeset
    end
  end

  defp validate_availment_or_policy_keys("Policy", changeset) do
    with true <- Map.has_key?(changeset.changes, :loa_facilitated) or
                 Map.has_key?(changeset.changes, :reimbursement)
    do
      Changeset.add_error(changeset,
                          :loa_facilitated,
                          "loa_facilitated/reimbursement: Keys should not exist in Benefit Policy"
      )
    else
      _ ->
        changeset
    end
  end

  defp validate_benefit_availment(changeset) do
    policy =  changeset.changes.type
    if policy == "Policy" do
      validate_availment_or_policy_keys(policy, changeset)
    else
      validate_availment_or_policy_keys(policy, changeset)
    end
  end

  defp validate_fields_policy(params) do
    types = %{
      type: :string,
      name: :string,
      code: :string,
      coverage_ids: :string,
      coverages: {:array, :string},
      category: :string,
      acu_package_ids: :string,
      updated_by_id: :binary_id,
      created_by_id: :binary_id,
      step: :integer,
      classification: :string,
      loa_facilitated: :boolean,
      reimbursement: :boolean,
      risk_share_type: :string,
      risk_share_value: :decimal,
      member_pays_handling: {:array, :string}
    }

    changeset =
      {%{}, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([
        :name,
        :code,
        :category,
        :coverages,
        :type
      ], message: "is required")
      |> Changeset.validate_inclusion(:category, [
        "Riders",
        "Health"
      ], message: "is invalid")
      |> validate_coverages()
      |> validate_benefit_availment()
      |> validate_classification()
      |> Changeset.validate_inclusion(:type, ["Policy", "policy"], message: "is invalid")
      |> Changeset.validate_inclusion(:classification, ["Standard", "Custom", "standard", "custom"], message: "is invalid")
      |> Changeset.validate_format(:code, ~r/^[a-zA-Z0-9_.-]*$/, message: "has invalid format")
      |> Changeset.validate_length(:code, max: 50, message: "must not exceed 50 characters")
      |> Changeset.validate_length(:name, max: 400, message: "must not exceed 400 characters")
      |> Changeset.validate_inclusion(:risk_share_type, ["None", "none", "Copay", 
            "copay", "Coinsurance", "coinsurance"], message: "is invalid")
      |> Changeset.validate_subset(:member_pays_handling, ["ASO override", "aso override", "Corporate Guarantee", 
              "corporate guarantee", "Ex-Gratia", "ex-gratia", 
              "Fee for Service", "fee for service", "Member pays", "member pays"], message: "is invalid")
      |> validate_risk_share()
      |> validate_code()

    if changeset.valid? do
      {:ok, changeset}
    else
      {:changeset_error, changeset}
    end
  end

  defp validate_acu_limit(changeset) do
    with true <- Map.has_key?(changeset.changes, :coverages),
         {:yes} <- acu_coverage?(changeset.changes.coverages),
         true <- Map.has_key?(changeset.changes, :limits),
         1 <- Enum.count(changeset.changes.limits),
         changeset <- validate_acu_limits_params(changeset)
    do
      limits_coverages =
        changeset.changes.limits
        |> Enum.map(&(&1["coverages"]))
        |> List.flatten()

      if Enum.sort(changeset.changes.coverages) == Enum.sort(limits_coverages) do
        changeset
      else
        Changeset.add_error(changeset, :limits, "is invalid")
      end
    else
      {:no} ->
        changeset
      false -> 
        changeset
      _ ->
        Changeset.add_error(changeset, :limits, "is invalid")
    end
  end

  defp validate_acu_limits_params(changeset) do
    checker = for limit <- changeset.changes.limits do
      coverages = Map.get(limit, "coverages") || []
      with true <- is_list(coverages),
           false <- Enum.member?(coverages, nil)
      do
        coverages =
          coverages
          |> Enum.join(", ")

        valid_limits_params_acu? Map.put(limit, "coverages", coverages), []
      else
        _ ->
          ["is invalid"]
      end
    end

    if checker == [""] do
      changeset
    else
      checker = 
        checker
        |> Enum.join(", ")

      Changeset.add_error(changeset, :limits, checker)
    end
  end

  defp valid_limits_params_acu?(params, errors) do
    types = %{
      coverages: :string,
      limit_amount: :decimal,
      limit_session: :integer,
      limit_percentage: :decimal,
      limit_type: :string,
      limit_classification: :string
    }
    changeset =
      {%{}, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([
        :coverages,
        :limit_type,
        :limit_classification
      ])
      |> Changeset.validate_inclusion(:limit_classification, [
        "Per Transaction", "per transaction", 
        "Per Coverage Period", "per coverage period",
        ], message: "is invalid")
      |> Changeset.validate_inclusion(:limit_type, [
        "Peso", "peso",
        "Sessions", "sessions",
        "Plan Limit Percentage", "plan limit percentage"
        ], message: "is invalid")
      |> validate_limit_value()

    if changeset.valid? do
      ""
    else
      changeset_errors = UtilityContext.changeset_errors_to_string(changeset.errors)
      errors = errors ++ ["row 1 error (#{changeset_errors})"]
    end
  end

  defp validate_limit_value(changeset) do
    case String.downcase(changeset.changes.limit_type) do
      "peso" ->
        changeset = 
          changeset
          |> Changeset.validate_required([
            :limit_amount,
          ])
          |> Changeset.validate_number(:limit_amount, greater_than: 0, message: "must be greater than zero")

          if changeset.valid? do 
            if Regex.match?(~r/^\s*(?=.*[1-9])\d*(?:\.\d{1,2})?\s*$/, Decimal.to_string(changeset.changes.limit_amount)) do
              changeset
              |> validate_limit_amount()
            else
              add_error_changeset(changeset, :limit_amount, "accepts only numerical and two decimal places value")
            end
          else
            changeset
          end
      "sessions" ->
        changeset = 
          changeset
          |> Changeset.validate_required([
            :limit_session,
          ])
          |> Changeset.validate_number(:limit_session, greater_than: 0, message: "must be greater than zero")

        if changeset.valid? do 
          if Regex.match?(~r/^[0-9]*$/, Integer.to_string(changeset.changes.limit_session)) do
            changeset
            |> validate_limit_session()
          else
            add_error_changeset(changeset, :limit_session, "accepts only numerical.")
          end
        else
          changeset
        end
        
      "plan limit percentage" ->
        changeset =
          changeset
          |> Changeset.validate_required(:limit_percentage)
          |> Changeset.validate_number(:limit_percentage, greater_than: 0, less_than: 101, message: "should be not less than 0 or greater than 100")
          
          if changeset.valid? do 
            if Regex.match?(~r/^\s*(?=.*[1-9])\d*(?:\.\d{1,2})?\s*$/, Decimal.to_string(changeset.changes.limit_percentage)) do
              changeset
              |> validate_limit_percentage()
            else
              add_error_changeset(changeset, :limit_percentage, "accepts only numerical and two decimal places value")
            end
          else
            changeset
          end
        
      _ ->
        changeset =
          changeset
          |> Changeset.add_error(:limit_type, "is invalid")
    end
  end

  defp validate_limit_amount(changeset) do
    if String.contains?(Decimal.to_string(changeset.changes.limit_amount), ".") do
      if String.length(Decimal.to_string(changeset.changes.limit_amount)) > 9 do
        Changeset.add_error(changeset, :limit_amount, "do not accept more than 8 numeric characters (including 2 decimals in the count)")
      else
        changeset
      end
    else
      if String.length(Decimal.to_string(changeset.changes.limit_amount)) > 6 do
        Changeset.add_error(changeset, :limit_amount, "do not accept more than 6 numeric characters")
      else
        changeset
      end
    end
  end

  defp validate_limit_percentage(changeset) do
    if String.contains?(Decimal.to_string(changeset.changes.limit_percentage), ".") do
      if String.length(Decimal.to_string(changeset.changes.limit_percentage)) > 5 do
        Changeset.add_error(changeset, :limit_amount, "do not accept more than 4 numeric characters (including 2 decimals in the count)")
      else
        changeset
      end
    else
      if String.length(Decimal.to_string(changeset.changes.limit_percentage)) >= 3 do
        case Decimal.compare(changeset.changes.limit_percentage, Decimal.new(100)) do
          :gt ->
            Changeset.add_error(changeset, :limit_percentage, "should be not less than 0 or greater than 100")
          :lt ->
            Changeset.add_error(changeset, :limit_percentage, "do not accept more than 2 numeric characters")
          _ ->
            changeset
        end
      else
        changeset
      end
    end
  end

  defp validate_limit_session(changeset) do
    if String.length(Integer.to_string(changeset.changes.limit_session)) >= 3 do
      if changeset.changes.limit_session > 999 do
        Changeset.add_error(changeset, :limit_session, "should be not less than 0 or greater than 999")
      else
        changeset
      end
    else
      changeset
    end
  end

  defp validate_op_consult_diseases(%{changes: %{all_diagnosis: true}} = changeset), do: changeset

  defp validate_op_consult_diseases(changeset) do
    with true <- Map.has_key?(changeset.changes, :coverages) do
      if op_consult_included?(changeset) == true do
        changeset
        |> Changeset.validate_required([:diseases], message: "is required")
        |> Changeset.validate_length(:diseases, min: 1, message: "at least one is required")
      else
        changeset
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_limits(changeset) do
    with true <- Map.has_key?(changeset.changes, :coverages),
         {:no} <- acu_coverage?(changeset.changes.coverages),
         true <- Map.has_key?(changeset.changes, :limits),
         changeset <- validate_limits_params(changeset)
    do
      limits_coverages =
        changeset.changes.limits
        |> Enum.map(&(&1["coverages"]))
        |> List.flatten()
        
      if Enum.sort(changeset.changes.coverages) == Enum.sort(limits_coverages) do
        changeset
      else
        Changeset.add_error(changeset, :limits, "is invalid")
      end
    else
      {:yes} ->
        changeset
      _ ->
        Changeset.add_error(changeset, :limits, "is invalid")
    end
  end

  defp acu_coverage?(coverages) do
    if Enum.member?(coverages, "ACU") do
      {:yes}
    else
      {:no}
    end
  end

  defp validate_limits_params(%{changes: %{limits: limits}} = changeset) do
    coverage_checker = Enum.map(limits, fn(limit) -> 
      coverages = Map.get(limit, "coverages") || []
      with false <- Enum.member?(coverages, nil) do
          {:ok}
      else
        _ ->
          {:error}
      end
    end)

    if Enum.member?(coverage_checker, {:error}) do
      Changeset.add_error(changeset, :limits, "has invalid data")
    else
      checker = 
        limits
        |> Enum.with_index(1)
        |> valid_limits_params?([])
        |> Enum.join(", ")

      if checker == "" do
        changeset
      else
        Changeset.add_error(changeset, :limits, checker)
      end
    end
  end

  defp validate_limits_params(changeset), do: changeset

  defp validate_multiple_ids(array) do
    checker = Enum.map(array, &(UtilityContext.valid_uuid?(&1)))
    if Enum.member?(checker, {:invalid_id}) do
      {:invalid}
    else
      {:ok}
    end
  end

  defp valid_limits_params?([{params, index} | tails], errors) do
    types = %{
      coverages: {:array, :string},
      limit_type: :string,
      limit_amount: :decimal,
      limit_session: :integer,
      limit_percentage: :decimal,
      limit_classification: :string
    }

    changeset =
      {%{}, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([
        :coverages,
        :limit_type,  
        :limit_classification
      ])
      |> Changeset.validate_inclusion(:limit_classification, [
        "Per Transaction", "per transaction", 
        "Per Coverage Period", "per coverage period",
        ], message: "is invalid")
      |> Changeset.validate_inclusion(:limit_type, [
        "Peso", "peso",
        "Sessions", "sessions",
        "Plan Limit Percentage", "plan limit percentage"
        ], message: "is invalid")
      |> limit_type_validations(params)
      
    if changeset.valid? do
      valid_limits_params?(tails, errors)
    else
      changeset_errors = UtilityContext.changeset_errors_to_string(changeset.errors)
      errors = errors ++ ["row #{index} errors (#{changeset_errors})"]
      valid_limits_params?(tails, errors)
    end
  end

  defp valid_limits_params?([], errors), do: errors 

  defp limit_type_validations(changeset, params) do
    case String.downcase(params["limit_type"]) do
      "peso" ->
        changeset =
          changeset
          |> Changeset.validate_required(:limit_amount)
          |> Changeset.validate_number(:limit_amount, greater_than: 0, message: "must be greater than zero")
        
        if changeset.valid? do 
          if Regex.match?(~r/^\d+\.?\d*$/, Decimal.to_string(changeset.changes.limit_amount)) do
            changeset
            |> validate_limit_amount()
          else
            add_error_changeset(changeset, :limit_amount, "accepts only numerical.")
          end
        else
          changeset
        end

      "plan limit percentage" ->
        changeset =
          changeset
          |> Changeset.validate_required(:limit_percentage)
          |> Changeset.validate_number(:limit_percentage, greater_than: 0, less_than: 101, message: "should be not less than 0 or greater than 100")
          
          if changeset.valid? do 
            if Regex.match?(~r/^\s*(?=.*[1-9])\d*(?:\.\d{1,2})?\s*$/, Decimal.to_string(changeset.changes.limit_percentage)) do
              changeset
              |> validate_limit_percentage()
            else
              add_error_changeset(changeset, :limit_percentage, "accepts only numerical and two decimal places value")
            end
          else
            changeset
          end

      "sessions" ->
        changeset = 
          changeset
          |> Changeset.validate_required([
            :limit_session,
          ])
          |> Changeset.validate_number(:limit_session, greater_than: 0, message: "must be greater than zero")

        if changeset.valid? do 
          if Regex.match?(~r/^[0-9]*$/, Integer.to_string(changeset.changes.limit_session)) do
            changeset
            |> validate_limit_session()
          else
            add_error_changeset(changeset, :limit_session, "accepts only numerical.")
          end
        else
          changeset
        end

      _ ->
        changeset =
          changeset
          |> Changeset.add_error(:limit_type, "is invalid")
    end
  end

  defp validate_count(changeset, key) do
    if Enum.count(Map.get(changeset.changes, key)) < 1 do
      Changeset.add_error(changeset, key, "at least one is required")
    else
      changeset
    end
  end

  defp validate_ruv_count(changeset) do
    with true <- Map.has_key?(changeset.changes, :coverages),
         true <- Enum.member?(changeset.changes.coverages, "RUV")
    do
      if Map.has_key?(changeset.changes, :ruvs) do
        validate_count(changeset, :ruvs)
      else
        Changeset.add_error(changeset, :ruvs, "at least one is required")
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_procedure_count_lvl1(changeset) do
    with true <- Map.has_key?(changeset.changes, :all_procedure),
         true <- changeset.changes.all_procedure
    do
      changeset
    else
      false ->
        validate_procedure_count(changeset)
    end
  end

  defp validate_procedure_count(changeset) do
    with true <- Map.has_key?(changeset.changes, :coverages),
         false <- Enum.member?(changeset.changes.coverages, "ACU"),
         false <- Enum.member?(changeset.changes.coverages, "OPC"),
         true <- Map.has_key?(changeset.changes, :procedures)
    do
      if Enum.count(changeset.changes.procedures) < 1 do
        Changeset.add_error(changeset, :procedures, "at least one is required")
      else
        changeset
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_code(changeset) do
    Changeset.validate_change changeset, :code, fn :code, code ->
      if Enum.member?(get_all_benefit_codes(), String.downcase(code)) do
        [code: "already exists"]
      else
        []
      end
    end
  end

  defp maternity_validations(changeset) do
    with true <- Map.has_key?(changeset.changes, :coverages),
         true <- Enum.member?(changeset.changes.coverages, "MTRNTY"),
         true <- validate_maternity_parameters(changeset)
    do
      changeset
    else
      {:invalid_maternity_params, maternity_changeset} ->
        Changeset.merge(changeset, maternity_changeset)
      _ ->
        changeset
    end
  end

  defp acu_validations(changeset) do
    with true <- Map.has_key?(changeset.changes, :coverages),
         true <- Enum.member?(changeset.changes.coverages, "ACU"),
         true <- validate_acu_parameters(changeset)
    do
      changeset
    else
      {:invalid_acu_params, acu_changeset} ->
        Changeset.merge(changeset, acu_changeset)
      _ ->
        changeset
    end
  end

  defp validate_maternity_parameters(changeset) do
    maternity_changeset =
      changeset
      |> Changeset.validate_required([
        :maternity_type,
      ], message: "is required")
      |> Changeset.validate_inclusion(:maternity_type, [
        "Consultation",
        "Inpatient Laboratory",
        "Outpatient Laboratory"
      ], message: "is invalid")
      |> validate_maternity_diseases()
    if maternity_changeset.valid? do
      true
    else
      {:invalid_maternity_params, maternity_changeset}
    end
  end

  defp validate_maternity_diseases(changeset) do
    with true <- Map.has_key?(changeset.changes, :maternity_type) do
      case changeset.changes.maternity_type do
        "Consultation" ->
          changeset
          |> Changeset.validate_required([:diseases], message: "is required")
          |> Changeset.validate_length(:diseases, min: 1, message: "at least one is required")
        _ ->
          changeset
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_acu_parameters(changeset) do
    acu_changeset =
      changeset
      |> Changeset.validate_required([
        :acu_type,
        :peme,
        :provider_access,
        :packages
      ], message: "is required")
      |> Changeset.validate_inclusion(:provider_access, [
        "Hospital",
        "Clinic",
        "Mobile",
        "Hospital and Clinic",
        "Clinic and Mobile",
        "Hospital and Mobile",
        "Hospital and Clinic and Mobile"
      ], message: "is invalid")
      |> Changeset.validate_inclusion(:acu_type, [
        "Executive",
        "Regular"
      ], message: "is invalid")
      |> Changeset.validate_length(:packages, min: 1, message: "at least one is required")
      |> validate_acu_coverage()
    if acu_changeset.valid? do
      #true
      validate_acu_parameters2(acu_changeset)
    else
      {:invalid_acu_params, acu_changeset}
    end
  end

  defp validate_acu_parameters2(changeset) do
    changeset =
      changeset
      |> validate_acu_packages()

    if changeset.valid? do
      true
    else
      {:invalid_acu_params, changeset}
    end
  end

  defp validate_acu_packages(changeset) do
    packages = changeset.changes.packages

    package_params =
      packages
      |> generate_package_params([])
      |> check_overlapping_package(changeset, [])
  end

  defp check_overlapping_package([head | tails], changeset, changeset_list) do
    male_changeset =
      tails
      |> check_package(head, changeset, "male")

    female_changeset =
      tails
      |> check_package(head, changeset, "female")

    changeset_list = changeset_list ++ [male_changeset, female_changeset]

    check_overlapping_package(tails, changeset, changeset_list)
  end

  defp check_overlapping_package([], changeset, changeset_list), do: merge_changeset_errors(changeset_list, changeset)

  defp check_package([head | tails], package, changeset, gender) do
    current_package = get_param_by_gender(package, gender)
    package_to_compare = get_param_by_gender(head, gender)

    cond do
      current_package.max < package_to_compare.min ->
        check_package(tails, package, changeset, gender)
      current_package.max == 0 and package_to_compare.min == 0 ->
        check_package(tails, package, changeset, gender)
      current_package.max >= package_to_compare.min ->
        changeset = check_package_level2(package_to_compare, current_package, changeset, gender)
        check_package(tails, package, changeset, gender)
      true ->
        check_package(tails, package, changeset, gender)
    end
  end

  defp check_package([], package, changeset, gender), do: changeset

  defp check_package_level2(head, package, changeset, gender) do
    cond do
      package.min < head.max ->
        Changeset.add_error(changeset, :packages, "cannot be added: #{package.name}'s age bracket (#{gender}) overlaps with #{head.name}'s")
      package.min > head.max ->
        changeset
      true ->
        changeset
    end
  end

  defp get_param_by_gender(package, gender) do
    case gender do
      "male" ->
        %{
          name: package.name,
          min: package.male_min,
          max: package.male_max
        }
      "female" ->
        %{
          name: package.name,
          min: package.female_min,
          max: package.female_max
        }
    end
  end

  defp generate_package_params([head | tails], params) do
    package = get_package_by_code(head)

    {male_min, male_max} =
      package.package_payor_procedure
      |> Enum.filter(&(&1.male == true))
      |> get_package_param()

    {female_min, female_max} =
      package.package_payor_procedure
      |> Enum.filter(&(&1.female == true))
      |> get_package_param()

    params =
      params ++
        [%{
          name: package.name,
          male_min: male_min,
          male_max: male_max,
          female_min: female_min,
          female_max: female_max
        }]

    generate_package_params(tails, params)
  end

  defp generate_package_params([], params), do: params

  defp get_package_param(param) do
    param
    |> Enum.map(&([&1.age_from, &1.age_to]))
    |> List.flatten()
    |> get_min_max()
  end

  defp get_min_max([]), do: {0, 0}
  defp get_min_max(ages), do: ages |> Enum.min_max

  defp merge_changeset_errors([head | tails], changeset) do
    prev_changeset = changeset
    new_changeset = head
    merge_changeset_errors(tails, Changeset.merge(prev_changeset, new_changeset))
  end

  defp merge_changeset_errors([], changeset), do: changeset

  defp validate_acu_coverage(changeset) do
    with true <- Map.has_key?(changeset.changes, :acu_type) do
      case changeset.changes.acu_type do
        "Regular" ->
          changeset
          |> Changeset.validate_required([
            :limits
          ], message: "is required")
        "Executive" ->
          changeset = 
            changeset
            |> Changeset.validate_required([
              :acu_coverage
            ], message: "is required")

          if changeset.valid? do
            Changeset.validate_inclusion(changeset, :acu_coverage, ["Inpatient", "Outpatient"])
          else
            changeset
          end
        _ ->
          Changeset.add_error(changeset, :acu_coverage, "is invalid")
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_op_consult(changeset) do
    with true <- op_consult_included?(changeset),
         true <- Enum.count(changeset.changes.coverages) == 1
    do
      {:ok}
    else
      {:no_op_consult} ->
        {:ok}
      _ ->
        {:invalid_coverages}
    end
  end

  defp op_consult_included?(changeset) do
    if Enum.member?(changeset.changes.coverages, "OPC") do
      true
    else
      {:no_op_consult}
    end
  end

  defp validate_classification(changeset) do
    with true <- Map.has_key?(changeset.changes, :coverages),
       coverages <- changeset.changes.coverages
    do
      validate_classification_coverage(coverages, changeset)
    else
      _ ->
      changeset
    end
  end

  defp validate_classification_coverage(coverage, changeset) do
    with true <- Enum.member?(coverage, "ACU") or Enum.member?(coverage, "PEME"),
         true <- Map.has_key?(changeset.changes, :classification)
    do
      Changeset.add_error(changeset, :classification, "Key must not exist when coverage #{coverage}.")
    else
      _ ->
        changeset
    end
  end

  defp validate_coverages(changeset) do
    with true <- Map.has_key?(changeset.changes, :coverages),
         true <- Map.has_key?(changeset.changes, :category),
         {:ok} <- validate_coverage_category(changeset),
         {:ok} <- validate_op_consult(changeset)
    do
      changeset
    else
      {:no_classification} ->
        changeset
        |> Changeset.validate_required([
          :classification
        ], message: "is required")
        
      {:invalid_coverages} ->
        Changeset.add_error(changeset, :coverages, "is invalid")
       _ ->
        changeset
    end
  end

  defp validate_coverage_category(changeset) do
    if changeset.changes.category == "Health" do
      valid_coverages = get_coverages_by_type("health_plan")
    else
      valid_coverages = get_coverages_by_type("riders")
    end

    if Enum.empty?(changeset.changes.coverages -- valid_coverages) do
      if changeset.changes.category == "Riders" do
        if Enum.count(changeset.changes.coverages) > 1 do
          {:invalid_coverages}
        else
          {:ok}
        end
      else
        if Map.has_key?(changeset.changes, :classification) do
          {:ok}
        else
          {:no_classification}
        end
      end
    else
      {:invalid_coverages}
    end
  end

  defp get_coverages_by_type(type) do
    Coverage
    |> where([c], c.plan_type == ^type)
    |> select([c], c.code)
    |> Repo.all()
  end

  defp get_coverage_by_code(code) do
    Coverage
    |> where([c], c.code == ^code)
    |> select([c], c.code)
    |> Repo.one()
  end

  defp get_coverage_data_by_code(code) do
    Coverage
    |> where([c], c.code == ^code)
    |> select([c], c)
    |> Repo.one()
  end

  defp get_procedure_by_code(code) do
    PayorProcedure
    |> where([pp], pp.code == ^code and pp.is_active == true)
    |> limit(1)
    |> Repo.one()
  end

  defp get_all_benefit_codes do
    Benefit
    |> select([b], fragment("lower(?)", b.code))
    |> Repo.all()
  end

  defp get_ruv_by_code(code) do
    RUV
    |> where([r], r.code == ^code)
    |> Repo.one()
  end

  defp get_all_procedure_codes do
    PayorProcedure
    |> where([pp], pp.is_active == true)
    |> select([pp], pp.code)
    |> Repo.all()
  end

  defp get_all_ruv_codes do
    RUV
    |> select([r], r.code)
    |> Repo.all()
  end

  defp get_coverage_name(id) do
    Coverage
    |> where([c], c.id == ^id)
    |> select([c], c.code)
    |> Repo.one()
  end

  defp get_all_package_codes do
    Package
    |> select([p], p.code)
    |> Repo.all()
  end

  defp get_all_disease_codes do
    Diagnosis
    |> select([d], d.code)
    |> Repo.all()
  end

  defp get_package_by_code(code) do
    Package
    |> where([p], p.code == ^code)
    |> Repo.one()
    |> Repo.preload([
      :package_log ,
      package_facility: [:facility],
      package_payor_procedure: [payor_procedure: [:procedure]]
    ])
  end

  defp get_disease_by_code(code) do
    Diagnosis
    |> where([d], d.code == ^code)
    |> Repo.one()
  end

  defp validate_added_maternity_validation(changeset) do
    if Map.has_key?(changeset.changes, :coverages) do
      if Enum.member?(changeset.changes.coverages, "MTRNTY") do
        changeset
        |> validate_covered_enrollees
        |> validate_waiting_period
      else
        changeset
      end
    else
      changeset
    end
  end

  defp validate_covered_enrollees(changeset) do
    valid_list = ["single enrollees", "married only", "married only and spouse of male employees"]

    if Map.has_key?(changeset.changes, :covered_enrollees) do
      covered_enrollees = String.downcase(changeset.changes.covered_enrollees)
      if Enum.member?(valid_list, covered_enrollees) do
        word_array = String.split(covered_enrollees, " ")
        result = [] ++ for w <- word_array do
          uppercase_word(w)
        end
        |> Enum.join(" ")
        Changeset.put_change(
        changeset,
        :covered_enrollees,
        result
      )
      else
        Changeset.add_error(changeset, :covered_enrollees, "Not a valid Covered Enrollees")
      end
    else
      Changeset.add_error(changeset, :covered_enrollees, "No selected Covered Enrollees")
    end
  end

  defp convert_string_to_boolean(true), do: true
  defp convert_string_to_boolean(false), do: false
  defp convert_string_to_boolean(string)
  when string == "true" or string == "false"
  do
    if string == "true", do: true, else: false
  end
  defp convert_string_to_boolean(string), do: nil

  defp validate_waiting_period(changeset) do
    valid_list = ["waived", "not waived"]

    if Map.has_key?(changeset.changes, :waiting_period) do
      waiting_period = String.downcase(changeset.changes.waiting_period)
      if Enum.member?(valid_list, waiting_period) do
        word_array = String.split(waiting_period, " ")
        result = [] ++ for w <- word_array do
          uppercase_word(w)
        end
        |> Enum.join(" ")
        Changeset.put_change(
          changeset,
          :waiting_period,
          result
        )
      else
        Changeset.add_error(changeset, :waiting_period, "Not a valid waiting period")
      end
    else
      Changeset.add_error(changeset, :waiting_period, "No selected waiting period")
    end
  end

  defp uppercase_word(word) do
    # Converts every word in camel case format.

    word = String.downcase(word)
    case word do
      "to" ->
        word
      "and" ->
        word
      "of" ->
        word
      _ ->
        field =
          word
          |> String.split("")
          |> List.delete("")

        first_letter =
          field
          |> List.first
          |> String.upcase

        _field =
          field
          |> List.replace_at(0, first_letter)
          |> List.to_string
    end
  end

  def get_benefit_dental(benefit_code_name, page_number, with_cdt?) do
    with %Benefit{} = benefit <- MainBenefitContext1.get_benefit_dental_by_code_or_name(benefit_code_name, page_number, with_cdt?) do
      {:ok, benefit}
    end
  end

  defp validate_risk_share(changeset) do
    if Map.has_key?(changeset.changes, :risk_share_type) do
      if String.downcase(changeset.changes.risk_share_type) == "none" || changeset.changes.risk_share_type == "" do
        changes = 
          changeset.changes
          |> Map.put(:risk_share_value, "")
          |> Map.put(:risk_share_type, "None")

        changeset
        |> Map.put(:changes, changes)
      else
        with {:ok, :risk_share_type} <- validate_has_key_field(changeset, :risk_share_type),
            {:ok, :member_pays_handling} <- validate_has_key_field(changeset, :member_pays_handling),
            {:ok, :risk_share_value} <- validate_has_key_field(changeset, :risk_share_value)
        do
          validate_risk_share_value(changeset)
        else
          {:error, :member_pays_handling} ->
            add_error_changeset(changeset, :member_pays_handling, "is required")
          {:error, :risk_share_value} ->
            add_error_changeset(changeset, :risk_share_value, "is required")
          {:error, :risk_share_type} ->
            add_error_changeset(changeset, :risk_share_type, "is required")
        end
      end
    else
      changeset
    end
  end

  defp validate_risk_share_value(changeset) do
    case String.downcase(changeset.changes.risk_share_type) do
      "copay" ->
        if Regex.match?(~r/^\s*(?=.*[1-9])\d*(?:\.\d{1,2})?\s*$/, Decimal.to_string(changeset.changes.risk_share_value)) do
          changeset
          |> validate_risk_share_copay()
        else
          add_error_changeset(changeset, :risk_share_value, "accepts only numerical.")
        end
      "coinsurance" ->
        if Regex.match?(~r/^\s*(?=.*[1-9])\d*(?:\.\d{1,2})?\s*$/, Decimal.to_string(changeset.changes.risk_share_value)) do
          changeset
          |> Changeset.validate_number(:risk_share_value, greater_than: 0, less_than: 101, message: "should be not less than 0 or greater than 100")
          |> validate_risk_share_coinsurance()
        else
          add_error_changeset(changeset, :risk_share_value, "should be not less than 0 or greater than 100")
        end
    end
  end

  defp validate_risk_share_copay(changeset) do
    if String.contains?(Decimal.to_string(changeset.changes.risk_share_value), ".") do
      if String.length(Decimal.to_string(changeset.changes.risk_share_value)) > 9 do
        Changeset.add_error(changeset, :risk_share_value, "do not accept more than 8 numeric characters (including 2 decimals in the count)")
      else
        changeset
      end
    else
      if String.length(Decimal.to_string(changeset.changes.risk_share_value)) > 6 do
        Changeset.add_error(changeset, :risk_share_value, "do not accept more than 6 numeric characters")
      else
        changeset
      end
    end
  end

  defp validate_risk_share_coinsurance(changeset) do
    if String.contains?(Decimal.to_string(changeset.changes.risk_share_value), ".") do
      if String.length(Decimal.to_string(changeset.changes.risk_share_value)) > 6 do
        Changeset.add_error(changeset, :risk_share_value, "do not accept more than 6 numeric characters (including 2 decimals in the count)")
      else
        changeset
      end
    else
      if String.length(Decimal.to_string(changeset.changes.risk_share_value)) > 3 do
        Changeset.add_error(changeset, :risk_share_value, "do not accept more than 3 numeric characters")
      else
        changeset
      end
    end
  end

  defp validate_has_key_field(changeset, field) do
    if Map.has_key?(changeset.changes, field) do
      {:ok, field}
    else
      {:error, field}
    end
  end

  defp add_error_changeset(changeset, field, message) do
    Changeset.add_error(
      changeset,
      field,
      message
    )
  end

  ## REGEX PATTERN
  ## ACCEPTS WHOLE NUMBER AND 2 DECIMAL PLACES
  ## ^\s*(?=.*[1-9])\d*(?:\.\d{1,2})?\s*$

end
