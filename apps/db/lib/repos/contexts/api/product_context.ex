defmodule Innerpeace.Db.Base.Api.ProductContext do
  import Ecto.{Query, Changeset}, warn: false

  @moduledoc """
    Context regarding Product API Module.
  """

  alias Innerpeace.Db.{
    Repo,
    Schemas.Product,
    Schemas.Benefit,
    Schemas.Coverage,
    Schemas.Facility,
    Schemas.BenefitLimit,
    Schemas.Payor,
    Schemas.ProductExclusion,
    Schemas.Exclusion,
    Schemas.Member,
    Schemas.ProductCoverage,
    Schemas.ProductCoverageLimitThreshold,
    Schemas.ProductCoverageLimitThresholdFacility,
    Schemas.ProductCoverageRoomAndBoard,
    Schemas.FacilityPayorProcedure,
    Schemas.Room,
    Schemas.ProductBenefit,
    Schemas.ProductBenefitLimit,
    Schemas.Dropdown
  }

  alias Innerpeace.Db.Base.ProductContext, as: MainProductContext
  alias Innerpeace.Db.Base.{
    AccountContext,
    FacilityContext,
    LocationGroupContext,
    MemberContext,
    BenefitContext,
    Api.UtilityContext
  }

  import Ecto.Query

  def get_all_products do
    # Returns all products in the database.

    Product
    |> Repo.all()
    |> Repo.preload([
      :account_products,
      :payor,
      :logs,
      :product_condition_hierarchy_of_eligible_dependents,
      product_benefits: [
        :product_benefit_limits,
        benefit: [
          :created_by,
          :updated_by,
          :benefit_limits,
          benefit_procedures: [
            procedure: [
              :procedure
            ]
          ],
          benefit_coverages: :coverage,
          benefit_packages: [
            package: [
              package_payor_procedure: [
                payor_procedure: [
                  :procedure
                ]
              ]
            ]
          ]
        ]
      ],
      product_coverages: [
        :coverage,
        :product_coverage_room_and_board,
        product_coverage_facilities: [facility: [:category, :type, facility_location_groups: :location_group]],
        product_coverage_risk_share: [
          product_coverage_risk_share_facilities: [
            :facility, product_coverage_risk_share_facility_payor_procedures: [
              :facility_payor_procedure
            ]
          ]
        ]
      ],
      product_exclusions: [exclusion: [:exclusion_diseases, :exclusion_procedures]],
      ]
    )
  end

  def get_all_products_queried(params) do
    # Returns all products in the database.

    product = if is_nil(params) or params == %{} or params == %{"code" => nil} do
      Product
      |> Repo.all()
    else
      _code = params["code"]
      Product
      |> where([p], fragment("lower(?)", p.code) == fragment("lower(?)", ^params["code"]))
      |> Repo.all()
    end

    product
    |> Repo.preload([
      :account_products,
      :payor,
      :logs,
      :product_condition_hierarchy_of_eligible_dependents,
      product_benefits: [
        :product_benefit_limits,
        benefit: [
          :created_by,
          :updated_by,
          :benefit_limits,
          benefit_procedures: [
            procedure: [
              :procedure
            ]
          ],
          benefit_coverages: :coverage,
          benefit_diagnoses: :diagnosis,
          benefit_packages: [
            package: [
              package_payor_procedure: [
                payor_procedure: [
                  :procedure
                ]
              ]
            ]
          ]
        ]
      ],
      product_coverages: [
        :coverage,
        :product_coverage_room_and_board,
        product_coverage_facilities: [facility: [:category, :type, facility_location_groups: :location_group]],
        product_coverage_risk_share: [
          product_coverage_risk_share_facilities: [
            :facility, product_coverage_risk_share_facility_payor_procedures: [
              :facility_payor_procedure
            ]
          ]
        ]
      ],
      product_exclusions: [exclusion: [:exclusion_diseases, :exclusion_procedures]],
      ]
    )
  end

  def load_room(id) do
    if is_nil(id) do
      nil
    else
      Room
      |> where([r], r.id == ^id)
      |> Repo.one
    end
  end

  defp validate_pb_exist(user, params, changeset, product_base) do
    if Enum.member?(["benefit-based", "exclusion-based"], String.downcase(product_base)) do
      case String.downcase(product_base) do
        "benefit-based" ->
          validate_benefit_based(user, params)
        "exclusion-based" ->
          validate_exclusion_based(user, params)
      end
    else
       if product_base == "" do
        changeset_with_error =
          add_error(
            changeset, :product_base,
            "Empty string is not accepted. Please enter 'Benefit-based' or 'Exclusion-based'."
          )
      else
        changeset_with_error =
          add_error(
            changeset, :product_base,
            "'#{product_base}' is invalid. Please enter 'Benefit-based' or 'Exclusion-based'."
          )
      end

      {:error, changeset_with_error}
    end
  end

  def validate_insert(user, params) do
    # Top-level validation: Validates credentials and correct product base.

    if is_nil(user) do
      {:invalid_credentials}
    else
      product_base = params["product_base"]
      changeset =
        {%{}, %{product_base: :string}}
        |> cast(
          %{"product_base" => product_base},
          Map.keys(%{product_base: :string})
        )

      if not is_nil(product_base) do
        validate_pb_exist(user, params, changeset, product_base)
      else
        changeset_with_error =
        add_error(
          changeset, :product_base,
          "Product Base can't be blank."
        )
        {:error, changeset_with_error}
      end
    end
  end

  # Start of the validation of benefit based products.

  defp validate_benefit_based(user, params) do
    # Validates benefit based product.
    # If the product passed the validation, it will be inserted.

    with {:ok, changeset} <- validate_benefit_based_level1(params),
         {:ok, product} <- insert_product(changeset, user),
         {:ok} <- insert_exclusion(changeset, product),
         {:ok} <- insert_benefit(changeset, product, user),
         {:ok} <- insert_benefit_with_limits(changeset, product),
         {:ok} <- insert_product_coverage_facility(changeset, product),
         {:ok} <- insert_condition(changeset, product),
         {:ok} <- insert_limit_threshold(changeset, product),
         {:ok} <- insert_product_coverage_risk_share(changeset, product)
    do
      product = MainProductContext.get_product(product.id)
      {:ok, product}
    else
      {:error, changeset} ->
        {:error, changeset}
      {:error} ->
        {:error, "Only one ACU can be added"}
      {:error_overlapping_age, message} ->
        {:error, message}
      # _ ->
      #   {:not_found}
    end
  end

  defp check_bb_dummy_changeset(dummy_changeset) do
    # Check Benefit Based Dummy changeset
    if dummy_changeset.valid? do
      dummy_changeset
      |> validate_member_type(:member_type)
      |> validate_limit_applicability(:limit_applicability)
      |> validate_is_medina(:is_medina)
    else
      dummy_changeset
    end
  end

  defp validate_benefit_based_level1(params) do
    # Checks if fields are empty.

    dummy_data = %{}
    dummy_general_types = %{
      product_base: :string,
      member_type: {:array, :string},
      is_medina: :string,
      loa_facilitated: :string,
      limit_applicability: :string
    }

    dummy_changeset =
      {dummy_data, dummy_general_types}
      |> cast(params, Map.keys(dummy_general_types))
      |> validate_required([
        :product_base,
        :member_type,
        :limit_applicability,
        :is_medina
      ])

    dummy_changeset = check_bb_dummy_changeset(dummy_changeset)

    if dummy_changeset.valid? do
      validate_benefit_based_level1_1(dummy_changeset, params)
    else
      {:error, dummy_changeset}
    end

  end

  defp validate_benefit_based_level1_1(dummy_changeset, params) do
    parameter_validator = validate_params(
      Map.keys(params),
      "Benefit-based",
      dummy_changeset.changes[:member_type],
      dummy_changeset.changes[:is_medina],
      dummy_changeset.changes[:limit_applicability]
    )
    if parameter_validator == true do
      data = %{}
      general_types = %{
        code: :string,
        name: :string,
        description: :string,
        limit_applicability: :string,
        shared_limit_amount: :string,
        type: :string,
        limit_type: :string,
        limit_amount: :string,
        phic_status: :string,
        standard_product: :string,
        product_category: :string,
        member_type: {:array, :string},
        product_base: :string,
        exclusion: :map,
        benefit: {:array, :map},
        coverage: {:array, :string},
        facility: {:array, :map},
        nem_principal: :string,
        nem_dependent: :string,
        no_outright_denial: :string,
        no_of_days_valid: :integer,
        is_medina: :string,
        loa_facilitated: :string,
        medina_processing_limit: :string,
        hierarchy_waiver: :string,
        sop_principal: :string,
        sop_dependent: :string,
        principal_min_age: :string,
        principal_min_type: :string,
        principal_max_age: :string,
        principal_max_type: :string,
        adult_dependent_min_age: :string,
        adult_dependent_min_type: :string,
        adult_dependent_max_age: :string,
        adult_dependent_max_type: :string,
        minor_dependent_min_age: :string,
        minor_dependent_min_type: :string,
        minor_dependent_max_age: :string,
        minor_dependent_max_type: :string,
        overage_dependent_min_age: :string,
        overage_dependent_min_type: :string,
        overage_dependent_max_age: :string,
        overage_dependent_max_type: :string,
        adnb: :string,
        adnnb: :string,
        opmnb: :string,
        opmnnb: :string,
        funding_arrangement: {:array, :map},
        rnb: {:array, :map},
        risk_share: {:array, :map},
        limit_threshold: {:array, :map}
      }
      changeset =
        {data, general_types}
        |> cast(params, Map.keys(general_types))
        |> validate_required([
          :name,
          :description,
          :limit_applicability,
          :type,
          :limit_type,
          :limit_amount,
          :phic_status,
          :standard_product,
          :product_category,
          :member_type,
          :benefit,
          :facility,
          :product_base,
          :adult_dependent_min_age,
          :adult_dependent_min_type,
          :adult_dependent_max_age,
          :adult_dependent_max_type,
          :minor_dependent_min_age,
          :minor_dependent_min_type,
          :minor_dependent_max_age,
          :minor_dependent_max_type,
          :overage_dependent_min_age,
          :overage_dependent_min_type,
          :overage_dependent_max_age,
          :overage_dependent_max_type,
          :funding_arrangement,
          :hierarchy_waiver,
          :no_of_days_valid,
          :is_medina,
          :loa_facilitated,
          :no_outright_denial
        ])
        |> validate_list_fields(:principal_min_type, ["years", "months", "weeks", "days"])
        |> validate_list_fields(
          :sop_principal,
          ["annual", "daily", "hourly", "monthly", "quarterly", "semi annual", "weekly"]
        )
        |> validate_list_fields(
          :sop_dependent,
          ["annual", "daily", "hourly", "monthly", "quarterly", "semi annual", "weekly"]
        )
        |> validate_list_fields(:no_outright_denial, ["true", "false"])
        |> validate_list_fields(:hierarchy_waiver, ["enforce", "skip allowed", "waive"])
        |> validate_inclusion(:no_of_days_valid, 1..100, message: "should be 1 - 100 value")
        |> validate_list_fields(:is_medina, ["yes", "no"])
        |> validate_list_fields(:loa_facilitated, ["true", "false"])
        |> validate_list_fields(:type, ["platinum", "gold", "silver", "bronze", "platinum plus"])
        |> validate_list_fields(:limit_applicability, ["principal", "share with dependents"])
        |> validate_list_fields(:limit_type, ["mbl", "abl"])
        |> validate_list_fields(:phic_status, ["required to file", "optional to file"])
        |> validate_list_fields(:standard_product, ["yes", "no"])
        |> validate_list_fields(:product_category, ["regular plan", "peme plan"])
        |> validate_list_fields(:product_base, ["benefit-based", "exclusion-based"])
        |> validate_list_fields(:principal_min_type, ["years", "months", "weeks", "days", "month"])
        |> validate_list_fields(:principal_max_type, ["years", "months", "weeks", "days", "month"])
        |> validate_list_fields(:adult_dependent_min_type, ["years", "months", "weeks", "days"])
        |> validate_list_fields(:adult_dependent_max_type, ["years", "months", "weeks", "days"])
        |> validate_list_fields(:minor_dependent_min_type, ["years", "months", "weeks", "days"])
        |> validate_list_fields(:minor_dependent_max_type, ["years", "months", "weeks", "days"])
        |> validate_list_fields(:overage_dependent_min_type, ["years", "months", "weeks", "days"])
        |> validate_list_fields(:overage_dependent_max_type, ["years", "months", "weeks", "days"])
        |> validate_length(:benefit, min: 1, message: "at least one is required")

      new_changeset =
        changeset.changes
        |> Map.put_new(:principal_min_age, "")
        |> Map.put_new(:principal_max_age, "")
        |> Map.put_new(:adult_dependent_min_age, "")
        |> Map.put_new(:adult_dependent_max_age, "")
        |> Map.put_new(:minor_dependent_min_age, "")
        |> Map.put_new(:minor_dependent_max_age, "")
        |> Map.put_new(:overage_dependent_min_age, "")
        |> Map.put_new(:overage_dependent_max_age, "")
        |> Map.put_new(:nem_principal, "")
        |> Map.put_new(:nem_dependent, "")
        |> Map.put_new(:limit_amount, "")
        |> Map.put_new(:medina_processing_limit, "")
        |> Map.put_new(:adnb, "")
        |> Map.put_new(:adnnb, "")
        |> Map.put_new(:opmnb, "")
        |> Map.put_new(:opmnnb, "")

      lower_member_type =
        changeset.changes[:member_type]
        |> Enum.map(fn(x) -> String.downcase(x) end)

      changeset = if lower_member_type != ["dependent"] do
        changeset =
          changeset
          |> validate_required([
            :principal_min_age,
            :principal_min_type,
            :principal_max_age,
            :principal_max_type,
          ])
          |> validate_all_number_fields(new_changeset.principal_min_age, :principal_min_age)
          |> validate_all_number_fields(new_changeset.principal_max_age, :principal_max_age)
          |> validate_all_number_fields(new_changeset.nem_principal, :nem_principal)

          if changeset.valid? do
            changeset
            |> validate_min_age_max_age(
              new_changeset.principal_min_age,
              new_changeset.principal_max_age,
              :principal_min_age,
              :principal_max_age
            )
          else
            changeset
          end
      else
        changeset
      end

      ######### start: checks if params have a missing key conformity to the conditions ##########    ***Benefit Base

      ## for medina_processing_limit
      changeset = if String.downcase(changeset.changes[:is_medina]) == "yes" do
        changeset =
          changeset
          |> validate_required([
            :medina_processing_limit,
          ])

          result = if changeset.valid? do
            changeset =
              changeset
              |> validate_all_decimal_fields(changeset.changes.medina_processing_limit, :medina_processing_limit)

              changeset.valid?
          else
            changeset.valid?
          end

          if result == true do
            changeset
            |> validate_medina_plimit(changeset.changes.medina_processing_limit, :medina_processing_limit)
          else
            changeset
          end
      else
        changeset
      end

      ## for share with dependents
      changeset = if String.downcase(changeset.changes[:limit_applicability]) == "share with dependents" do
        changeset =
          changeset
          |> validate_required([
            :shared_limit_amount,
          ])

          with true <- changeset.valid?,
               {:success, changeset} <- check_sla_if_decimal(
                 changeset,
                 changeset.changes.shared_limit_amount,
                 :shared_limit_amount),
               changeset <- check_sla_amount(
                 changeset,
                 changeset.changes.shared_limit_amount,
                 :shared_limit_amount
               )

          do
            changeset
          else
            false ->
              changeset

            {:error, changeset} ->
              changeset

            _ ->
              changeset
          end

      else
      ## limit applicability == "principal"
      changeset
      end

      ## for sop_principal or sop_dependent referencing member_type ["Principal",  "Dependent"]
      changeset =
        changeset.changes[:member_type]
        |> Enum.map(fn(x) -> String.downcase(x) end)
        |> Enum.sort()
        |> changeset_required(changeset)

        ######### end: checks if params have a missing key conformity to the conditions ##########    ***Benefit Base

        changeset =
          changeset
          |> validate_all_number_fields(new_changeset.adult_dependent_min_age, :adult_dependent_min_age)
          |> validate_all_number_fields(new_changeset.adult_dependent_max_age, :adult_dependent_max_age)
          |> validate_min_age_max_age(
            new_changeset.adult_dependent_min_age,
            new_changeset.adult_dependent_max_age,
            :adult_dependent_min_age,
            :adult_dependent_max_age
          )
          |> validate_all_number_fields(new_changeset.minor_dependent_min_age, :minor_dependent_min_age)
          |> validate_all_number_fields(new_changeset.minor_dependent_max_age, :minor_dependent_max_age)
          |> validate_min_age_max_age(
            new_changeset.minor_dependent_min_age,
            new_changeset.minor_dependent_max_age,
            :minor_dependent_min_age,
            :minor_dependent_max_age
          )
          |> validate_all_number_fields(new_changeset.overage_dependent_min_age, :overage_dependent_min_age)
          |> validate_all_number_fields(new_changeset.overage_dependent_max_age, :overage_dependent_max_age)
          |> validate_min_age_max_age(
            new_changeset.overage_dependent_min_age,
            new_changeset.overage_dependent_max_age,
            :overage_dependent_min_age,
            :overage_dependent_max_age
          )
          |> validate_all_number_fields(new_changeset.nem_dependent, :nem_dependent)
          |> validate_all_decimal_fields(new_changeset.limit_amount, :limit_amount)
          |> validate_all_decimal_fields(new_changeset.adnb, :adnb)
          |> validate_all_decimal_fields(new_changeset.adnnb, :adnnb)
          |> validate_all_decimal_fields(new_changeset.opmnb, :opmnb)
          |> validate_all_decimal_fields(new_changeset.opmnnb, :opmnnb)

        if changeset.valid? do
          validate_benefit_based_level1_2(changeset)
        else
          {:error, changeset}
        end
    else
    parameter_validator
    end
  end

  defp validate_benefit_based_level1_2(changeset) do
    benefit_param = get_field(changeset, :benefit)
    checker = Enum.map(benefit_param, &(validate_benefit_params(&1)))
    if Enum.member?(checker, {:invalid}) do
      {:error, add_error(changeset, :benefit, "is invalid")}
    else
      validate_benefit_based_level2(changeset)
    end
  end

  defp validate_benefit_params(params) do
    fields = %{
      code: :string,
      coverage: {:array, :map}
    }
    changeset =
      {%{}, fields}
      |> cast(params, Map.keys(fields))
      |> validate_required([
        :code
      ])
      |> validate_benefit_code()
      |> validate_coverage_codes()
      |> validate_benefit_coverages()
    if changeset.valid? do
      {:valid}
    else
      {:invalid}
    end
  end

  defp validate_benefit_code(changeset) do
    with true <- Map.has_key?(changeset.changes, :code) do
      benefit = get_benefit(changeset.changes.code)
      if is_nil(benefit) do
        add_error(changeset, :code, "is invalid")
      else
        put_change(changeset, :benefit, benefit)
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_coverage_codes(changeset) do
    with true <- changeset.valid?,
         true <- Map.has_key?(changeset.changes, :coverage),
         false <- Enum.empty?(changeset.changes.coverage)
    do
      bc =
        changeset.changes.benefit.benefit_coverages
        |> Enum.map(&(&1.coverage.code))
      params = get_all_coverage_codes(changeset.changes.coverage)
      if Enum.count(bc) == Enum.count(params) do
        changeset
      else
        add_error(changeset, :coverage, "is invalid")
      end
    else
      _ ->
        changeset
    end
  end

  defp get_all_coverage_codes(benefit_coverages) do
    benefit_coverages
    |> Enum.filter(fn(coverage) ->
      Map.has_key?(coverage, "code")
    end)
    |> Enum.map(&(&1["code"]))
    |> List.flatten()
  end

  defp validate_benefit_coverages(changeset) do
    with true <- changeset.valid?,
         true <- Map.has_key?(changeset.changes, :coverage),
         false <- Enum.empty?(changeset.changes.coverage)
    do
      bc = Enum.map(changeset.changes.benefit.benefit_coverages, &(&1.coverage.code))
      checker =
        Enum.map(changeset.changes.coverage, fn(coverage) ->
          validate_coverage(coverage, bc)
        end)
      if Enum.member?(checker, false) do
        add_error(changeset, :coverage, "is invalid")
      else
        changeset
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_coverage(coverage_params, benefit_coverages) do
    fields = %{
      limit_value: :string,
      limit_type: :string,
      code: {:array, :string},
      limit_classification: :string
    }
    changeset =
      {%{}, fields}
      |> cast(coverage_params, Map.keys(fields))
      |> validate_subset(:code, benefit_coverages, message: "is invalid")
      |> validate_required([
        :code,
        :limit_value,
        :limit_classification
      ])
      |> validate_inclusion(:limit_type, [
        "Plan Limit Percentage",
        "Peso",
        "Sessions"
      ], message: "is invalid")
      |> validate_inclusion(:limit_classification, [
        "Per Transaction",
        "Per Coverage Period"
      ], message: "is invalid")
      |> validate_limit_value()
      |> validate_limit_type()
    changeset.valid?
  end

  defp validate_limit_value(%{
    changes: %{
      limit_type: "Plan Limit Percentage",
      limit_value: limit_value
    }
  } = changeset) do
    if Enum.member?(generate_string_list(), limit_value) do
      changeset
    else
      add_error(changeset, :limit_value, "should be 1-100")
    end
  end

  defp validate_limit_value(%{
    changes: %{
      limit_type: "Sessions",
      limit_value: limit_value
    }
  } = changeset) do
    with true <- validate_numbers(limit_value),
         true <- String.to_integer(limit_value) > 0
    do
      changeset
    else
      _ ->
        add_error(changeset, :limit_value, "is invalid")
    end
  end

  defp validate_limit_value(%{
    changes: %{
      limit_type: "Peso",
      limit_value: limit_value
    }
  } = changeset) do
    validate_format(changeset, :limit_value, ~r/^[0-9]*(\.[0-9]{1,90})?$/)
  end

  defp validate_limit_value(changeset), do: changeset

  defp generate_string_list do
    for x <- 1..100, do: Integer.to_string(x)
  end

  defp validate_limit_type(changeset) do
    with true <- Map.has_key?(changeset.changes, :code),
         false <- Enum.member?(changeset.changes.code, "ACU")
    do
      validate_required(changeset, :limit_type)
    else
      _ ->
        changeset
    end
  end

  defp validate_benefit_based_level2(changeset) do
    # Validates product category and exclusions.

    changeset =
      changeset
      |> validate_peme()
      |> validate_exclusion()

    if changeset.valid? do
      validate_benefit_based_level3(changeset)
    else
      {:error, changeset}
    end
  end

  def benefit_codes_from_params(params) do
    params
    |> Enum.map(&(&1["code"]))
  end

  defp validate_benefit_based_level3(changeset) do
    # Validates benefit
    benefit_param = get_field(changeset, :benefit)
    benefit_codes = benefit_codes_from_params(benefit_param)
    benefits =
      benefit_codes
      |> Enum.map(fn(x) -> if is_nil(get_benefit(x)) do x else "valid" end end)
      |> Enum.uniq()
      |> List.delete("valid")

    if Enum.empty?(benefits) do
      benefit_ids =
        benefit_codes
        |> Enum.map(&(get_benefit(&1).id))

      benefit_ids
      |> Enum.map(&(
        BenefitContext.get_benefit(&1).benefit_coverages
        |> Enum.into([], fn(x) -> if x.coverage.name == "ACU",
          do: &1
        end)
      ))

      |> List.flatten()
      |> Enum.filter(fn(b) -> b != nil end)
      |> Enum.map(fn(a) -> MainProductContext.check_benefit_acu_state(BenefitContext.get_benefit(a)) end)
      |> List.flatten()
      |> Enum.filter(fn(y) -> y.acu_type == "Executive" and y.acu_coverage == "Inpatient" end)
      |> contains_exec_inpatient2?()


      changeset =
        changeset
        |> validate_benefit()
    else
      benefits =
        benefits
        |> Enum.join(", ")

      changeset =
        add_error(changeset, :benefit, "Benefit code not found: #{benefits}")
    end

    if changeset.valid? do
      validate_benefit_based_level4(changeset)
    else
      {:error, changeset}
    end
  end

  def contains_exec_inpatient2?(list) do
    if Enum.empty?(list) do
      false
    else
      true
    end
  end

  defp validate_benefit_based_level4(changeset) do
    # Validates facility, funding arrangement, rnb, and risk share.

    changeset =
      changeset
      |> validate_facility()
      |> validate_funding_arrangement()
      |> validate_rnb()
      |> validate_risk_share()
      |> validate_limit_threshold()

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp validate_benefit(changeset) do
    # Validates benefit codes entered.

    benefits =
      changeset
      |> get_field(:benefit)
      |> benefit_codes_from_params()

    product_category = get_field(changeset, :product_category)
    if benefits != %{} do
      if benefits != [] do
        result = for b <- benefits do
          record = get_benefit(b)
          if not is_nil(record) do
            check_b_peme_prod(changeset, record, product_category, b)
          else
            check_valid_benefit(changeset, b)
          end
        end

        result =
          result
          |> List.flatten
          |> Enum.uniq
          |> List.delete(nil)

        if result == [] do
          validate_benefit_level2(changeset)
        else
          merge_changeset_errors(result, changeset)
        end
      else
        add_error(changeset, :benefit, "At least one benefit code is required.")
      end
    else
      add_error(changeset, :benefit, "Invalid paramters.")
    end
  end

  defp check_b_peme_prod(changeset, record, product_category, b) do
    if product_category == "PEME Product" do
      coverages = for bc <- record.benefit_coverages do
        bc.coverage.name
      end

      coverage =
        coverages
        |> List.delete("ACU")

      if not Enum.empty?(coverage) do
        add_error(
          changeset,
          :benefit,
          "#{b} is not an ACU. ACU is the only coverage that is accepted in PEME Products."
        )
      end
    end
  end

  defp check_valid_benefit(changeset, b) do
    if b == "" do
      add_error(changeset, :benefit, "Empty strings are not accepted.")
    else
      add_error(changeset, :benefit, "#{b} does not exist.")
    end
  end

  def validate_benefit_level2(changeset) do
    # Check codes if the number of ACU is not greater than one and if does not exceeded product's limit amount.
    with true <- validate_ACU_benefits(changeset),
         true <- validate_benefit_inner_limit(changeset),
         true <- validate_benefit_inner_limit_from_params(changeset)
    do
      validate_benefit_level3(changeset)
    else
      {:many_acu} ->
        add_error(changeset, :benefit, "Only one ACU is allowed in creating a Product.")
      {:greater_than_limit_amount} ->
        add_error(changeset, :benefit, "Limits of benefit entered is greater than product's limit amount.")
    end
  end

  defp validate_benefit_inner_limit_from_params(changeset) do
    limit_amount = get_field(changeset, :limit_amount)
    benefit_limits =
      changeset
      |> get_field(:benefit)
      |> Enum.filter(fn(b) ->
        coverage = b["coverage"]
        not is_nil(coverage) and not Enum.empty?(coverage)
      end)
      |> Enum.map(fn(b) ->
        amounts =
          Enum.map(b["coverage"], fn(coverage) ->
            validate_benefit_inner_limit_from_params_check_coverage(coverage)
          end)
        total_amount = Enum.reduce(amounts, Decimal.new(0), &Decimal.add/2)
        result = Decimal.compare(Decimal.new(limit_amount), total_amount)
        if result == Decimal.new(1) or result == Decimal.new(0) do
          true
        else
          false
        end
      end)
    if Enum.member?(benefit_limits, false) do
      {:greater_than_limit_amount}
    else
      true
    end
  end

  defp validate_benefit_inner_limit_from_params_check_coverage(coverage) do
    if Enum.member?(coverage["code"], "ACU") do
      Decimal.new(coverage["limit_value"])
    else
      if coverage["limit_type"] == "Peso" do
        Decimal.new(coverage["limit_value"])
      else
        Decimal.new("0")
      end
    end
  end

  defp validate_benefit_level3(changeset) do
    original_list =
      changeset.changes.benefit
      |> benefit_codes_from_params()

    uniq_list =
      original_list
      |> Enum.uniq

    result = original_list -- uniq_list

    error = for {b, _index} <- Enum.with_index(original_list, 1) do
      if Enum.member?(result, String.downcase(b)) do
         add_error(changeset, :benefit, "#{String.downcase(b)} is duplicated")
      end
    end

    result =
      error
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

    if result == [] do
      benefits = get_field(changeset, :benefit)
      valid_coverages = for b <- original_list do
        record = get_benefit(b)
        for bc <- record.benefit_coverages do
          bc.coverage.code
        end
      end

      valid_coverages =
        valid_coverages
        |> List.flatten
        |> Enum.uniq

      put_change(changeset, :coverage, valid_coverages)
    else
      merge_changeset_errors(result, changeset)
    end

  end

  defp validate_benefit_level2_1(changeset) do
    benefit_param = get_field(changeset, :benefit)
    benefit_codes = benefit_param["code"]
    benefit_ids =
      benefit_codes
      |> Enum.map(&(get_benefit(&1).id))

    with {:recursion_done} <- MainProductContext.validate_male_multiple_acu(benefit_ids),
         {:recursion_done} <- benefit_ids |> MainProductContext.validate_female_multiple_acu(),
         {:zero_to_100_fulfilled} <- validate_acu_age(benefit_ids)
    do
      validate_benefit_level3(changeset)
    else
      {:error_overlapping_age, message} ->
        add_error(changeset, :benefit, "#{message}")

      {:unfulfilled_age_female, message} ->
        add_error(changeset, :benefit, "#{message}")

      {:no_pb_acu_found} ->
        ### this product doesn't have at least one acu benefit, so this is valid,
        # and no age and gender validation required
        validate_benefit_level3(changeset)

      {:unfulfilled_age_male, message} ->
        add_error(changeset, :benefit, "#{message}")

    end
  end

  defp validate_acu_age(benefit_ids) do
    benefit_ids
    |> Enum.map(fn(a) ->
      a
      |> BenefitContext.get_acu_benefit()
      |> Enum.map(fn(b) ->
        BenefitContext.get_benefit(b).benefit_packages
        validate_acu_age_x(b)
      end)
    end)
    |> List.flatten()
    |> MainProductContext.remaining_acu_age_checker()
  end

  defp validate_acu_age_x(b) do
    b
    |> Enum.into([], fn(x) ->
      MainProductContext.get_ppp(x)
    end)
  end

  defp validate_ACU_benefits(changeset) do
    # Checks if ACU benefits is not greater than one.

    benefits =
      changeset
      |> get_field(:benefit)
      |> benefit_codes_from_params()
    result = for b <- benefits do
      record = get_benefit(b)
      _coverages = for bc <- record.benefit_coverages do
        if bc.coverage.name == "ACU" do
          "ACU"
        end
      end
    end
    result =
      result
      |> List.flatten
      |> Enum.filter(fn(x) -> x == "ACU" end)

    if Enum.member?(result, "ACU") do
      if Enum.count(result) > 1 do
        {:many_acu}
      else
        true
      end
    else
      true
    end
  end

  defp validate_benefit_inner_limit(changeset) do
    # Checks if all of benefit doesn't exceed product's limit amount.

    if changeset.changes[:product_category] != "PEME Product" do
      benefit_code =
        changeset.changes[:benefit]
        |> benefit_codes_from_params_without_limit()

      benefit_ids = bil_loop_benefit_ids(benefit_code)

      benefit_limits = bil_loop_benefit_limits(benefit_ids)

      benefit_limit =
        benefit_limits
        |> List.flatten
        |> deleting_list_element(nil)

      if is_nil(benefit_limit) do
        true
      else
        benefit_limit_result = [] ++ for bl <- benefit_limit do
          result = Decimal.compare(Decimal.new(changeset.changes.limit_amount), bl)
          if result == Decimal.new(1) or result == Decimal.new(0) do
            true
          else
            false
          end
        end
        if Enum.member?(benefit_limit_result, false) do
          {:greater_than_limit_amount}
        else
          true
        end
      end
    else
      true
    end
  end

  def benefit_codes_from_params_without_limit(params) do
    params
    |> Enum.filter(fn(param) ->
      coverage = param["coverage"]
      is_nil(coverage) or Enum.empty?(coverage)
    end)
    |> Enum.map(&(&1["code"]))
  end

  def filter_benefits_with_limit(benefits) do
    benefits
    |> Enum.filter(fn(param) ->
      coverage = param["coverage"]
      not is_nil(coverage) and not Enum.empty?(coverage)
    end)
  end

  defp bil_loop_benefit_ids(code) do
    # Benefit Inner Limit Loop Benefit Code

    for bc <- code do
      benefit =
        Benefit
        # |> where([b], ilike(b.code, ^bc))
        |> where([b], b.code == ^bc)
        |> Repo.one

      benefit.id
    end
  end

  defp bil_loop_benefit_limits(ids) do
    for b <- ids do
      if b != nil do
        benefit_limit =
          BenefitLimit
          |> where([bl], bl.benefit_id == ^b)
          |> Repo.all

          _benefit_limit_amounts = [] ++ for benefit_limit_amount <- benefit_limit do
            benefit_limit_amount.limit_amount
          end
      end
    end
  end

  defp deleting_list_element(list, element) do
    if Enum.member?(list, element) do
      new_list = List.delete(list, element)
      if Enum.member?(new_list, element) do
         deleting_list_element(new_list, element)
      else
        new_list
      end
    else
      list
    end
  end

  # End of the validation of benefit based products.

  # Start of the validation of exclusion based products.

  defp validate_exclusion_based(user, params) do
    with {:ok, changeset} <- validate_exclusion_based_level1(params),
         {:ok, product} <- insert_product(changeset, user),
         {:ok} <- insert_exclusion(changeset, product),
         {:ok} <- insert_coverage(changeset, product),
         {:ok} <- insert_product_coverage_facility(changeset, product),
         {:ok} <- insert_condition(changeset, product),
         {:ok} <- insert_limit_threshold(changeset, product),
         {:ok} <- insert_product_coverage_risk_share(changeset, product)
    do
      {:ok, product}
    else
      {:error, changeset} ->
        {:error, changeset}
      {:error} ->
        {:error, "Only one ACU can be added"}
      # _ ->
      #   {:not_found}
    end
  end

  defp validate_exclusion_based_level1(params) do
    # Checks if fields are empty.

    dummy_data = %{}
    dummy_general_types = %{
      product_base: :string,
      member_type: {:array, :string},
      is_medina: :string,
      limit_applicability: :string
    }

    dummy_changeset =
      {dummy_data, dummy_general_types}
      |> cast(params, Map.keys(dummy_general_types))
      |> validate_required([
        :product_base,
        :member_type,
        :limit_applicability,
        :is_medina
      ])
      |> validate_member_type(:member_type)
      |> validate_limit_applicability(:limit_applicability)
      |> validate_is_medina(:is_medina)

    if dummy_changeset.valid? do
      parameter_validator = validate_params(
        Map.keys(params),
        "Exclusion-based",
        dummy_changeset.changes[:member_type],
        dummy_changeset.changes[:is_medina],
        dummy_changeset.changes[:limit_applicability]
      )
      if parameter_validator == true do
        data = %{}
        general_types = %{
          code: :string,
          name: :string,
          description: :string,
          limit_applicability: :string,
          shared_limit_amount: :string,
          type: :string,
          limit_type: :string,
          limit_amount: :string,
          phic_status: :string,
          standard_product: :string,
          product_category: :string,
          member_type: {:array, :string},
          product_base: :string,
          coverage: {:array, :string},
          exclusion: :map,
          facility: {:array, :map},
          nem_principal: :string,
          nem_dependent: :string,
          no_outright_denial: :string,
          no_of_days_valid: :integer,
          is_medina: :string,
          loa_facilitated: :string,
          medina_processing_limit: :string,
          hierarchy_waiver: :string,
          sop_principal: :string,
          sop_dependent: :string,
          principal_min_age: :string,
          principal_min_type: :string,
          principal_max_age: :string,
          principal_max_type: :string,
          adult_dependent_min_age: :string,
          adult_dependent_min_type: :string,
          adult_dependent_max_age: :string,
          adult_dependent_max_type: :string,
          minor_dependent_min_age: :string,
          minor_dependent_min_type: :string,
          minor_dependent_max_age: :string,
          minor_dependent_max_type: :string,
          overage_dependent_min_age: :string,
          overage_dependent_min_type: :string,
          overage_dependent_max_age: :string,
          overage_dependent_max_type: :string,
          adnb: :string,
          adnnb: :string,
          opmnb: :string,
          opmnnb: :string,
          funding_arrangement: {:array, :map},
          rnb: {:array, :map},
          risk_share: {:array, :map},
          limit_threshold: {:array, :map}
        }
        required_list = [
          :name,
          :description,
          :limit_applicability,
          :type,
          :limit_type,
          :limit_amount,
          :phic_status,
          :standard_product,
          :product_category,
          :member_type,
          :product_base,
          :coverage,
          :facility,
          :adult_dependent_min_age,
          :adult_dependent_min_type,
          :adult_dependent_max_age,
          :adult_dependent_max_type,
          :minor_dependent_min_age,
          :minor_dependent_min_type,
          :minor_dependent_max_age,
          :minor_dependent_max_type,
          :overage_dependent_min_age,
          :overage_dependent_min_type,
          :overage_dependent_max_age,
          :overage_dependent_max_type,
          :funding_arrangement,
          :hierarchy_waiver,
          :no_of_days_valid,
          :is_medina,
          :loa_facilitated,
          :no_outright_denial
        ]
        changeset =
          {data, general_types}
          |> cast(params, Map.keys(general_types))
          |> validate_required(required_list)
          |> validate_list_fields(
            :sop_principal,
            ["annual", "daily", "hourly", "monthly", "quarterly", "semi annual", "weekly"]
          )
          |> validate_list_fields(
            :sop_dependent,
            ["annual", "daily", "hourly", "monthly", "quarterly", "semi annual", "weekly"]
          )
          |> validate_list_fields(:no_outright_denial, ["true", "false"])
          |> validate_list_fields(:hierarchy_waiver, ["enforce", "skip allowed", "waive"])
          |> validate_inclusion(:no_of_days_valid, 1..100, message: "should be 1 - 100 value")
          |> validate_list_fields(:is_medina, ["yes", "no"])
          |> validate_list_fields(:loa_facilitated, ["true", "false"])
          |> validate_list_fields(:type, ["platinum", "gold", "silver", "bronze"])
          |> validate_list_fields(:limit_applicability, ["principal", "share with dependents"])
          |> validate_list_fields(:limit_type, ["mbl", "abl"])
          |> validate_list_fields(:phic_status, ["required to file", "optional to file"])
          |> validate_list_fields(:standard_product, ["yes", "no"])
          |> validate_list_fields(:product_category, ["regular plan", "peme plan"])
          |> validate_list_fields(:principal_min_type, ["years", "months", "weeks", "days"])
          |> validate_list_fields(:principal_max_type, ["years", "months", "weeks", "days"])
          |> validate_list_fields(:adult_dependent_min_type, ["years", "months", "weeks", "days"])
          |> validate_list_fields(:adult_dependent_max_type, ["years", "months", "weeks", "days"])
          |> validate_list_fields(:minor_dependent_min_type, ["years", "months", "weeks", "days"])
          |> validate_list_fields(:minor_dependent_max_type, ["years", "months", "weeks", "days"])
          |> validate_list_fields(:overage_dependent_min_type, ["years", "months", "weeks", "days"])
          |> validate_list_fields(:overage_dependent_max_type, ["years", "months", "weeks", "days"])
          |> validate_list_fields(:product_base, ["benefit-based", "exclusion-based"])

          new_changeset =
            changeset.changes
            |> Map.put_new(:principal_min_age, "")
            |> Map.put_new(:principal_max_age, "")
            |> Map.put_new(:adult_dependent_min_age, "")
            |> Map.put_new(:adult_dependent_max_age, "")
            |> Map.put_new(:minor_dependent_min_age, "")
            |> Map.put_new(:minor_dependent_max_age, "")
            |> Map.put_new(:overage_dependent_min_age, "")
            |> Map.put_new(:overage_dependent_max_age, "")
            |> Map.put_new(:nem_principal, "")
            |> Map.put_new(:nem_dependent, "")
            |> Map.put_new(:limit_amount, "")
            |> Map.put_new(:adnb, "")
            |> Map.put_new(:adnnb, "")
            |> Map.put_new(:opmnb, "")
            |> Map.put_new(:opmnnb, "")

          lower_member_type =
            changeset.changes[:member_type]
            |> Enum.map(fn(x) -> String.downcase(x) end)

          changeset = if lower_member_type != ["dependent"] do
            _changeset =
              changeset
              |> validate_required([
                :principal_min_age,
                :principal_min_type,
                :principal_max_age,
                :principal_max_type,
              ])
              |> validate_all_number_fields(new_changeset.principal_min_age, :principal_min_age)
              |> validate_all_number_fields(new_changeset.principal_max_age, :principal_max_age)
              |> validate_all_number_fields(new_changeset.nem_principal, :nem_principal)
          else
            changeset
          end

          ######### start: checks if params have a missing key conformity to the conditions ########## ***Exclusion Base

          ## for medina_processing_limit
          changeset = if String.downcase(changeset.changes[:is_medina]) == "yes" do
            changeset =
              changeset
              |> validate_required([
                :medina_processing_limit,
              ])

              result = if changeset.valid? do
                changeset =
                  changeset
                  |> validate_all_decimal_fields(changeset.changes.medina_processing_limit, :medina_processing_limit)

                  changeset.valid?
              else
                changeset.valid?
              end

              if result == true do
                changeset
                |> validate_medina_plimit(changeset.changes.medina_processing_limit, :medina_processing_limit)
              else
                changeset
              end
          else
            changeset
          end

          ## for share with dependents
          changeset = if String.downcase(changeset.changes[:limit_applicability]) == "share with dependents" do
            changeset =
              changeset
              |> validate_required([
                :shared_limit_amount,
              ])

              with true <- changeset.valid?,
                   {:success, changeset} <- check_sla_if_decimal(
                     changeset,
                     changeset.changes.shared_limit_amount,
                     :shared_limit_amount
                   ),
                   changeset <- check_sla_amount(
                     changeset,
                     changeset.changes.shared_limit_amount,
                     :shared_limit_amount
                   )

              do
                changeset
              else
                false ->
                  changeset

                {:error, changeset} ->
                  changeset

                _ ->
                  changeset
              end

          else
            ## limit applicability == "principal"
            changeset
          end

          ## for sop_principal or sop_dependent referencing member_type ["Principal",  "Dependent"]
          changeset =
            changeset.changes[:member_type]
            |> Enum.map(fn(x) -> String.downcase(x) end)
            |> Enum.sort()
            |> changeset_required(changeset)

          ######### end: checks if params have a missing key conformity to the conditions ########## ***Exclusion Base

          changeset =
            changeset
            |> validate_all_number_fields(new_changeset.adult_dependent_min_age, :adult_dependent_min_age)
            |> validate_all_number_fields(new_changeset.adult_dependent_max_age, :adult_dependent_max_age)
            |> validate_all_number_fields(new_changeset.minor_dependent_min_age, :minor_dependent_min_age)
            |> validate_all_number_fields(new_changeset.minor_dependent_max_age, :minor_dependent_max_age)
            |> validate_all_number_fields(new_changeset.overage_dependent_min_age, :overage_dependent_min_age)
            |> validate_all_number_fields(new_changeset.overage_dependent_max_age, :overage_dependent_max_age)
            |> validate_all_number_fields(new_changeset.nem_dependent, :nem_dependent)
            |> validate_all_decimal_fields(new_changeset.limit_amount, :limit_amount)
            |> validate_all_decimal_fields(new_changeset.adnb, :adnb)
            |> validate_all_decimal_fields(new_changeset.adnnb, :adnnb)
            |> validate_all_decimal_fields(new_changeset.opmnb, :opmnb)
            |> validate_all_decimal_fields(new_changeset.opmnnb, :opmnnb)
            |> validate_min_age_max_age(
              new_changeset.principal_min_age,
              new_changeset.principal_max_age,
              :principal_min_age,
              :principal_max_age
            )
            |> validate_min_age_max_age(
              new_changeset.adult_dependent_min_age,
              new_changeset.adult_dependent_max_age,
              :adult_dependent_min_age,
              :adult_dependent_max_age
            )
            |> validate_min_age_max_age(
              new_changeset.minor_dependent_min_age,
              new_changeset.minor_dependent_max_age,
              :minor_dependent_min_age,
              :minor_dependent_max_age
            )
            |> validate_min_age_max_age(
              new_changeset.overage_dependent_min_age,
              new_changeset.overage_dependent_max_age,
              :overage_dependent_min_age,
              :overage_dependent_max_age
            )

          if changeset.valid? do
            validate_exclusion_based_level2(changeset)
          else
            {:error, changeset}
          end
      else
        parameter_validator
      end
    else
      {:error, dummy_changeset}
    end
  end

  defp validate_exclusion_based_level2(changeset) do
    # Validates product category and exclusion codes.

    changeset =
      changeset
      |> validate_peme()
      |> validate_exclusion()

    if changeset.valid? do
      validate_exclusion_based_level3(changeset)
    else
      {:error, changeset}
    end
  end

  defp validate_exclusion_based_level3(changeset) do
    # Validates coverages

    changeset =
      changeset
      |> validate_exclusion_based_coverage()

    if changeset.valid? do
      validate_exclusion_based_level4(changeset)
    else
      {:error, changeset}
    end
  end

  defp validate_exclusion_based_level4(changeset) do
    # Validates facility, funding arrangement, rnb, and risk_share

    changeset =
      changeset
      |> validate_facility()
      |> validate_funding_arrangement()
      |> validate_rnb()
      |> validate_risk_share()
      |> validate_limit_threshold()

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp validate_exclusion_based_coverage(changeset) do
    # Validates if the coverage entered are existing.

    if changeset.changes[:coverage] == [] do
      add_error(changeset, :coverage, "Coverage can't be blank.")
    else
      coverages = get_field(changeset, :coverage)
      result = for c <- coverages do
        record = get_coverage(c)
        if is_nil(record) do
          if c == "" do
            add_error(changeset, :coverage, "Empty strings are not accepted.")
          else
            add_error(changeset, :coverage, "#{c} does not exist.")
          end
        else
          if String.downcase(c) == "acu" do
            add_error(changeset, :coverage, "ACU is not allowed in exclusion based coverages.")
          end
        end
      end

      result =
        result
        |> List.flatten
        |> Enum.uniq
        |> List.delete(nil)

      if result == [] do
        changeset
      else
        merge_changeset_errors(result, changeset)
      end
    end
  end

  # End of the validation of exclusion based products.

  # Start of generic functions.

  defp validate_limit_threshold(changeset) do
    coverages = Enum.map(changeset.changes[:coverage], fn(x) -> String.downcase(x) end)
    if is_nil(changeset.changes[:limit_threshold]) do
      changeset
    else
      lt_records = changeset.changes[:limit_threshold]
      result = for {lt, index} <- Enum.with_index(lt_records, 1) do
        [
          check_coverage_lt(changeset, lt["coverage"], index, coverages),
          check_outer_lt(changeset, lt["limit_threshold"], index),
          check_lt_facilities(changeset, lt["limit_threshold_facilities"], index, lt["limit_threshold"])
        ]
      end
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

      if Enum.empty?(result) do
        changeset
      else
        merge_changeset_errors(result, changeset)
      end
    end
  end

  defp check_coverage_lt(changeset, coverage, index, coverages) do
    if is_nil(coverage) do
      add_error(
        changeset,
        :"limit_threshold_row#{index}",
        "Coverage is required."
      )
    else
      if not Enum.member?(coverages, String.downcase(coverage)) do
        if coverage == "" do
          add_error(
            changeset,
            :"limit_threshold_row#{index}",
            "Coverage: Empty strings are not accepted."
          )
        else
          add_error(
            changeset,
            :"limit_threshold_row#{index}",
            "Coverage: '#{coverage}' does not belong to available coverages of this product."
          )
        end
      end
    end
  end

  defp check_outer_lt(changeset, limit_threshold, index) do
    if is_nil(limit_threshold) do
      add_error(
        changeset,
        :"limit_threshold_row#{index}",
        "Limit Threshold is required."
      )
    else
      if limit_threshold == ""  do
        add_error(
          changeset,
          :"limit_threshold_row#{index}",
          "Limit Threshold: Empty strings are not accepted."
        )
      else
        if validate_decimal(limit_threshold) == false do
          add_error(
            changeset,
            :"limit_threshold_row#{index}",
            "Limit Threshold: '#{limit_threshold}' is not a valid amount."
          )
        end
      end
    end
  end

  defp check_lt_facilities(changeset, lt_facilities, index, olt) do
    if not is_nil(lt_facilities) do
      result = for {ltf, index_ltf} <- Enum.with_index(lt_facilities, 1) do
        [
          check_ltf_code(changeset, ltf["facility_code"], index, index_ltf),
          check_ltf_lt(changeset, ltf["limit_threshold"], index, index_ltf),
          check_olt(changeset, ltf["limit_threshold"], index, index_ltf, olt)
        ]
      end
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)
    end
  end

  defp check_olt(changeset, lt, index, index_ltf, olt) do
    with true <- not is_nil(olt),
         true <- not is_nil(lt)
    do
      if olt == lt do
        add_error(
          changeset,
          :"limit_threshold_row#{index}",
          "Limit Threshold Facility Row #{index_ltf}: Limit Threshold should not be equal to outer limit threshold."
        )
      end
    end
  end

  defp check_ltf_code(changeset, f_code, index, index_ltf) do
    if is_nil(f_code) do
      add_error(
        changeset,
        :"limit_threshold_row#{index}",
        "Limit Threshold Facility Row #{index_ltf}: Facility Code is required."
      )
    else
      facility = FacilityContext.get_facility_by_code(f_code)
      if is_nil(facility) do
        if f_code == "" do
          add_error(
            changeset,
            :"limit_threshold_row#{index}",
            "Limit Threshold Facility Row #{index_ltf}: (Facility Code) Empty strings are not accepted."
          )
        else
          add_error(
            changeset,
            :"limit_threshold_row#{index}",
            "Limit Threshold Facility Row #{index_ltf}: (Facility Code) '#{f_code}' does not exist."
          )
        end
      end
    end
  end

  defp check_ltf_lt(changeset, lt, index, index_ltf) do
    if is_nil(lt) do
      add_error(
        changeset,
        :"limit_threshold_row#{index}",
        "Limit Threshold Facility Row #{index_ltf}: Limit Threshold is required."
      )
    else
      if validate_decimal(lt) == false do
        add_error(
          changeset,
          :"limit_threshold_row#{index}",
          "Limit Threshold Facility Row #{index_ltf}: (Limit Threshold) '#{lt}' is not a valid amount."
        )
      else
        if lt == "" do
          add_error(
            changeset,
            :"limit_threshold_row#{index}",
            "Limit Threshold Facility Row #{index_ltf}: (Limit Threshold) Empty Strings are not accepted."
          )
        end
      end
    end
  end

  def validate_params(keys, product_category, member_type, is_medina, limit_applicability) do
    # Check if there was unwanted parameters.

    valid_keys = [
      "funding_arrangement",
      "member_type",
      "adult_dependent_max_type",
      "overage_dependent_max_age",
      "standard_product",
      "code",
      "phic_status",
      "overage_dependent_min_type",
      "limit_applicability",
      "opmnnb",
      "exclusion",
      "minor_dependent_max_age",
      "limit_amount",
      "risk_share",
      "adult_dependent_min_age",
      "limit_type",
      "nem_dependent",
      "opmnb",
      "rnb",
      "description",
      "minor_dependent_min_type",
      "overage_dependent_min_age",
      "adult_dependent_max_age",
      "product_base",
      "facility",
      "adult_dependent_min_type",
      "minor_dependent_min_age",
      "minor_dependent_max_type",
      "product_category",
      "overage_dependent_max_type",
      "name",
      "adnnb",
      "type",
      "adnb",
      "hierarchy_waiver",
      "no_of_days_valid",
      "is_medina",
      "no_outright_denial",
      "limit_threshold",
      "loa_facilitated",
      "capitation_fee",
      "dental_funding_arrangement",
      "loa_validity",
      "loa_validity_type",
      "mode_of_payment",
      "mode_of_payment_type",
      "special_handling_type",
      "type_of_payment"
    ]

    ## for product_category
    valid_keys = if product_category == "Benefit-based" do
      List.insert_at(valid_keys, 0, "benefit")
    else
      List.insert_at(valid_keys, 0, "coverage")
    end

    ######### start: checks if params have an excess key conformity to the conditions ##########

    ## for member_type
    member_type = for mt <- member_type, do: String.downcase(mt)
    valid_keys = if Enum.member?(member_type, "principal") do
      principal_keys = [
        "principal_min_type",
        "principal_min_age",
        "principal_max_type",
        "principal_max_age",
        "nem_principal"
      ]
      valid_keys ++ principal_keys
    else
      valid_keys
    end

    ## for sonny medina
    valid_keys = if String.downcase(is_medina) == "yes" do
      smp_key = [
        "medina_processing_limit"
      ]
      valid_keys ++ smp_key
    else
      valid_keys
    end

    ## for shared_limit_amount
    valid_keys = if String.downcase(limit_applicability) == "share with dependents" do
      sla_key = [
        "shared_limit_amount"
      ]
      valid_keys ++ sla_key
    else
      valid_keys
    end

    ## for schedule_of_payment reference to member_type
    valid_keys =
      member_type
      |> Enum.map(fn(x) -> String.downcase(x) end)
      |> Enum.sort()
      |> member_sop_checker()
      |> merge_list(valid_keys)

    ######### end: checks if params have an excess key conformity to the conditions ##########

    unwanted_params = keys -- valid_keys

    if unwanted_params == [] do
      true
    else
      data = %{}
      general_types = %{product: :string}

      dummy_changeset =
        {data, general_types}
        |> cast(%{product: "sample"}, Map.keys(general_types))

      result = for up <- unwanted_params do
        add_error(
          dummy_changeset,
          up,
          "'#{up}' does not belong to the list of accepted parameters."
        )
      end

      changeset_with_error =  merge_changeset_errors(result, dummy_changeset)
      {:error, changeset_with_error}
     end
  end

  defp member_sop_checker(member_type) do
    case member_type do
      ["dependent", "principal"] ->
        _sop_keys = [
          "sop_principal",
          "sop_dependent"
        ]
      ["principal"] ->
        _sop_keys = [
          "sop_principal"
        ]
      ["dependent"] ->
        _sop_keys = [
          "sop_dependent"
        ]
    end
  end

  defp merge_list(sop_keys, valid_keys) do
    valid_keys ++ sop_keys
  end

  def changeset_required(member_type, changeset) do
    case member_type do
      ["dependent", "principal"] ->
        changeset
        |> validate_required([
          :sop_principal,
          :sop_dependent
        ])

      ["principal"] ->
        changeset
        |> validate_required([
          :sop_principal,
        ])

      ["dependent"] ->
        changeset
        |> validate_required([
          :sop_dependent
        ])

    end
  end

  def get_coverage(name) do
    # Loads a coverage record by its name.

    Coverage
    |> where([c], ilike(c.name, ^name))
    |> Repo.one
  end

  def get_benefit(code) do
    # Loads a benefit record by its code.

    Benefit
    # |> where([b], ilike(b.code, ^code))
    |> where([b], b.code == ^code)
    |> Repo.one
    |> Repo.preload([
      benefit_coverages: :coverage
    ])
  end

  defp validate_min_age_max_age(changeset, min_age, max_age, field_min_age, field_max_age) do
    # Validates Age eligibility's minimum and maximum age.

    if Map.has_key?(changeset.changes, field_min_age) and Map.has_key?(changeset.changes, field_max_age) do
      if validate_numbers(min_age) and validate_numbers(max_age) do
        if String.to_integer(min_age) >= String.to_integer(max_age) do
          add_error(changeset, field_max_age, "Maximum age must be greater than minimum age")
        else
          changeset
        end
      else
        changeset
      end
    else
      changeset
    end
  end

  ## for shared_limit_amount
  defp check_sla_if_decimal(changeset, sla, field_sla) do
    changeset =
      changeset
      |> validate_all_decimal_fields(sla, field_sla)

    if changeset.valid? == true do
      {:success, changeset}
    else
      {:error, changeset}
    end
  end

  defp check_sla_amount(changeset, sla, field_sla) do
    changeset =
      changeset
      |> validate_sla_amount(changeset.changes.shared_limit_amount, :shared_limit_amount)

  end

  defp validate_sla_amount(changeset, sla, field_sla) do

    if Map.has_key?(changeset.changes, :limit_amount) do
      with false <- sla_is_zero?(sla),
           result <- check_sla_limit(sla, changeset.changes.limit_amount),
           {:valid} <- sla_result(result)
      do
        changeset
      else
        {:invalid} ->
          add_error(
            changeset,
            field_sla,
            "Shared Limit Amount should be in between 1 to #{changeset.changes.limit_amount} (limit_amount)"
          )

        true ->
          add_error(
            changeset,
            field_sla,
            "Shared Limit Amount should be in between 1 to #{changeset.changes.limit_amount} (limit_amount)"
          )

        _ ->
          raise "Invalid Decimal new, compare and to_integer"
      end

    else
      changeset
    end
  end

  defp sla_is_zero?(sla) do
    if sla == "0" do
      true
    else
      false
    end
  end

  defp check_sla_limit(sla, limit_amount) do
    sla =
      sla
      |> Decimal.new()
      |> Decimal.compare(Decimal.new(limit_amount))
      |> Decimal.to_integer()

  end

  defp sla_result(result) do
    case result do
      -1 ->
        {:valid}
      0 ->
        {:valid}
      1 ->
        {:invalid}
    end
  end

  ## for sonny medina processing limit
  defp validate_medina_plimit(changeset, smp_limit, field_smp_limit) do
    if Map.has_key?(changeset.changes, field_smp_limit) do
      with false <- smp_is_zero?(smp_limit),
           result <- check_smp_limit(smp_limit),
           {:valid} <- smp_result(result)
      do
        changeset
      else
        {:invalid} ->
          add_error(
            changeset,
            field_smp_limit,
            "Sonny Medina Processing Limit amount must be in between 1 to 100,000"
          )

        true ->
          add_error(
            changeset,
            field_smp_limit,
            "Sonny Medina Processing Limit amount must be in between 1 to 100,000"
          )

        _ ->
          raise "Invalid Decimal new, compare and to_integer" end

    else
      changeset
    end
  end

  defp smp_is_zero?(smp_limit) do
    if smp_limit == "0" do
      true
    else
      false
    end
  end

  defp check_smp_limit(smp_limit) do
    smp_limit =
      smp_limit
      |> Decimal.new()
      |> Decimal.compare(Decimal.new(100_000))
      |> Decimal.to_integer()
  end

  defp smp_result(result) do
    case result do
      -1 ->
        {:valid}
      0 ->
        {:valid}
      1 ->
        {:invalid}
    end
  end

  def validate_list_fields(changeset, field, list) do
    # Validates parameters entered as list.


    if is_nil(changeset.changes[field]) do
      changeset
    else
      field_input =
        changeset.changes[field]
        |> String.downcase()
        |> s_checker(field)

        if Enum.member?(list, field_input) do
          field_array = String.split(field_input, " ")
          result = [] ++ for f <- field_array do
            uppercase_word(f)
          end
          result = Enum.join(result, " ")
          put_change(changeset, field, result)
        else
          add_error(changeset, field, "'#{field_input}' is not valid.")
        end
    end
  end

  defp s_checker(value, field) do
    valid_list = [
      :principal_min_type,
      :principal_max_type,
      :adult_dependent_min_type,
      :adult_dependent_max_type,
      :minor_dependent_min_type,
      :minor_dependent_max_type,
      :overage_dependent_min_type,
      :overage_dependent_max_type
    ]

    if Enum.member?(valid_list, field) do
      case value do
        "year" ->
          "years"
        "month" ->
          "months"
        "week" ->
          "weeks"
        "day" ->
          "days"

        "years" ->
          "years"
        "months" ->
          "months"
        "weeks" ->
          "weeks"
        "days" ->
          "days"
      end
    else
      value
    end

  end

  defp uppercase_word(word) do
    # Converts every word in camel case format.

    word = String.downcase(word)
    case word do
      "to" ->
        word
      "with" ->
        word
      "abl" ->
        "ABL"
      "mbl" ->
        "MBL"
      "peme" ->
        "PEME"
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

  # unused defp
  # defp validate_list_array_fields(changeset, field, list) do
  #   # Validates parameters entered as list array.

  #   field_array = changeset.changes[field]

  #   result = [] ++ for fa <- field_array do
  #     String.downcase(fa)
  #   end
  #   if Enum.member?(list, result) do
  #     result = [] ++ for f <- changeset.changes[field] do
  #       word_array = String.split(f, " ")
  #       word = [] ++ for w <- word_array do
  #         uppercase_word(w)member
  #       end
  #     end
  #     result = List.flatten(result)
  #     put_change(changeset, field, result)
  #     else
  #     add_error(changeset, field, "Entered data is not valid.")
  #   end
  # end

  defp validate_peme(changeset) do
    # Validates Product Category

    if changeset.changes[:product_category] == "PEME Product" do
      if changeset.changes[:product_base] != "Benefit-based" do
        add_error(changeset, :product_category, "Only Benefit-based is allowed in PEME Product.")
      else
        changeset
      end
    else
      changeset
    end
  end

  defp validate_exclusion(changeset) do
    # Validates exclusion codes entered.
    if is_nil(changeset.changes[:exclusion]) do
      changeset
    else
      product_base =
        changeset.changes[:product_base]
        |> String.downcase

      exclusions = get_field(changeset, :exclusion)
      if exclusions != %{} and exclusions != %{"code" => []} do
        result = for e <- exclusions["code"] do
          record = get_exclusion(e)
          check_exclusion_level1(changeset, record, e, product_base)
        end

        result =
          result
          |> List.flatten
          |> Enum.uniq
          |> List.delete(nil)

          if result == [] do
            validate_exclusion_level2(changeset)
          else
            merge_changeset_errors(result, changeset)
          end
      else
        changeset
      end
    end
  end

  defp check_exclusion_level1(changeset, record, e, product_base) do
    if is_nil(record) do
      if e == "" do
        add_error(changeset, :exclusion, "Empty strings are not accepted.")
      else
        add_error(changeset, :exclusion, "#{e} does not exist.")
      end
    else
      if product_base == "benefit-based" do
        if record.coverage == "General Exclusion" do
          add_error(
            changeset,
            :exclusion,
            "#{e} is a General Exclusion. It can't be added with a Benefit-based product."
          )
        end
      end
    end
  end

  defp validate_exclusion_level2(changeset) do
    original_list = changeset.changes.exclusion["code"]
                    |> Enum.map(fn(x) -> String.downcase x end)

    uniq_list =
      original_list
      |> Enum.uniq

    result = original_list -- uniq_list

    error = for exclusion <- changeset.changes.exclusion["code"] do
      if Enum.member?(result, String.downcase(exclusion)) do
        add_error(changeset, :exclusion, "#{String.downcase(exclusion)} is duplicated")
      end
    end

    result =
      error
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

    if result == [] do
      changeset
    else
      merge_changeset_errors(result, changeset)
    end

  end

  defp get_exclusion(code) do
    # Loads an exclusion record.

    Exclusion
    |> where([e], ilike(e.code, ^code))
    |> Repo.one
  end

  def validate_member_type(changeset, field) do
    # Validates member type.

    member_type = changeset.changes[field]
    if member_type != [] do
      result = for mt <- member_type do
        record = String.downcase(mt)
        valid_array = ["dependent", "principal"]
        if Enum.member?(valid_array, record) do
          new_list = List.delete(changeset.changes[field], mt)
          if Enum.member?(new_list, mt) do
            add_error(changeset, :member_type, "#{mt} has a duplicate.")
          end
        else
          if mt == "" do
            add_error(changeset, :member_type, "Empty strings are not accepted.")
          else
            add_error(changeset, :member_type, "#{mt} is not a valid member type.")
          end
        end
      end

      result =
        result
        |> List.flatten
        |> Enum.uniq
        |> List.delete(nil)

      if result == [] do
        changeset
      else
        merge_changeset_errors(result, changeset)
      end
    else
      add_error(changeset, :member_type, "can't be blank.")
    end
  end

  defp validate_limit_applicability(changeset, field) do
    if not is_nil(changeset.changes[field]) do
      with {:valid_la} <- check_la_value(changeset, field) do
        changeset
      else
        {:invalid_la} ->
          add_error(changeset, field, "invalid limit_applicability, it should be ('principal' or 'share with dependents')")
      end
    else
      changeset
    end

  end

  defp check_la_value(changeset, field) do
    valid_la = ["principal", "share with dependents"]
    if Enum.member?(valid_la, String.downcase(changeset.changes[field])) do
      {:valid_la}
    else
      {:invalid_la}
    end
  end

  defp validate_is_medina(changeset, field) do
    if not is_nil(changeset.changes[field]) do
      with {:valid_medina} <- check_medina_value(changeset, field) do
        changeset
      else
        {:invalid_medina} ->
          add_error(changeset, field, "invalid is_medina")
      end
    else
      changeset
    end

  end

  defp check_medina_value(changeset, field) do
    valid_medina = ["yes", "no"]
    if Enum.member?(valid_medina, String.downcase(changeset.changes[field])) do
      {:valid_medina}
    else
      {:invalid_medina}
    end
  end

  ################################################# start of validation for facility_access
  def validate_facility(changeset) do
    facility_records = changeset.changes[:facility]
    coverages = Enum.map(changeset.changes[:coverage], fn(x) -> String.downcase(x) end)

    result = for {fr, index} <- Enum.with_index(facility_records, 1) do
      [
        check_coverage(changeset, fr["coverage"], index, coverages),
        check_type(changeset, fr["type"], index),
        check_code(changeset, fr["code"], fr["type"], index),
        check_location_group(changeset, fr["location_group"], fr["type"], index)
      ]
    end

    result =
      result
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)
      |> List.delete("")

    if result == [] do
     validate_facility_level2(changeset)
    else
      merge_changeset_errors(result, changeset)
    end
  end

  defp check_coverage(changeset, coverage, index, coverage_list) do
    if not is_nil(coverage) do
      if not Enum.member?(coverage_list, String.downcase(coverage)) do
        if coverage == "" do
          add_error(changeset, :"facility_row#{index}", "Coverage: Empty strings are not accepted.")
        else
          add_error(
            changeset,
            :"facility_row#{index}",
            "Coverage: '#{String.downcase coverage}' does not belong to available coverages of this plan."
          )
        end
      end
    else
      add_error(changeset, :"facility_row#{index}", "Coverage: Can't be blank.")
    end

  end

  defp check_type(changeset, type, index) do
    fa_type = ["exception", "inclusion", "all"]

    validate_ct(fa_type, type, index, changeset)
  end

  defp validate_ct(_, "", index, changeset), do:
    add_error(changeset, :"facility_row#{index}", "Type: Empty strings are not accepted.")
  defp validate_ct(_, nil, index, changeset), do:
    add_error(changeset, :"facility_row#{index}", "Type: Empty strings are not accepted.")
  defp validate_ct(fa_type, type, index, changeset), do:
    validate_ct_v2(not Enum.member?(fa_type, String.downcase("#{type}")), type, index, changeset)
  defp validate_ct_v2(true, type, index, changeset) do
    add_error(
      changeset,
      :"facility_row#{index}",
      "Type: '#{type}' is invalid, the only accepted type are 'Exception' or 'Inclusion'."
      )
  end
  defp validate_ct_v2(false, _, _, _), do: ""

  defp check_code(changeset, f_code, type, index) do
    case type do
      "all" ->
        check_code_exception(changeset, f_code, type, index)
      "exception" ->
        check_code_exception(changeset, f_code, type, index)
      "inclusion" ->
        check_code_inclusion(changeset, f_code, index)
      _ ->
      ### if the type was wrong same render of add_error on check type will render as one
      nil
    end
  end

  defp check_code_inclusion(changeset, f_code, index) do
    cond do
    f_code == [] or is_nil(f_code) ->
      add_error(changeset, :"facility_row#{index}", "Code: At least 1 facility code is required in inclusion type")
    not is_list(f_code) ->
      add_error(changeset, :"facility_row#{index}", "Code: Should be in array")
    true ->
      for facility_code <- f_code do
        facility = FacilityContext.get_facility_by_code(facility_code)
        if facility == nil do
          add_error(changeset, :"facility_row#{index}", "Code: #{facility_code} is not existing")
        end
      end
    end
  end

  defp check_code_exception(changeset, f_code, type, index) do
    coverages = changeset.changes[:coverage]
    if not is_nil(f_code) do
      for facility_code <- f_code do
        facility = FacilityContext.get_facility_by_code(facility_code)
        if facility == nil do
          check_code_level2(changeset, facility_code, index)
        end
      end
    end
  end

  defp check_code_level2(changeset, facility_code, index) do
    if facility_code == "" do
      add_error(changeset, :"facility_row#{index}", "Code: Empty strings are not accepted.")
    else
      add_error(changeset, :"facility_row#{index}", "Code: #{facility_code} is not existing")
    end
  end

  defp check_location_group(changeset, nil, type, index), do: nil
  defp check_location_group(changeset, [], type, index), do: nil
  defp check_location_group(changeset, location_groups, type, index) do
    existing = LocationGroupContext.get_all_names()
    Enum.map(location_groups, fn(location_group) ->
      check_location_group_v2(changeset, index, existing, location_group)
    end)
  end

  defp check_location_group_v2(changeset, index, existing, location_group) when location_group == "" do
    add_error(changeset, :"facility_row#{index}", "Location Group: Empty strings are not accepted.")
  end

  defp check_location_group_v2(changeset, index, existing, location_group) do
    if is_nil(Enum.find(existing, &(&1 == location_group))) do
      add_error(changeset, :"facility_row#{index}", "Location Group: #{location_group} is not existing")
    end
  end

  defp validate_facility_level2(changeset) do
    changeset =
      changeset
      |> validate_overall_coverage()
      |> validate_duplicated_coverage()
      |> validate_duplicated_facility_code()
      |> validate_duplicated_facility_location_group()

    if changeset.valid? do
      validate_facility_level3(changeset)
    else
      changeset
    end

  end

  defp check_pa(string, val) do
    if string =~ val do
      val
    else
      nil
    end
  end

  defp check_pa_recursion([head | tails], result) do
    provider_access = head.provider_access
    result = result ++ [
      check_pa(provider_access, "Hospital"),
      check_pa(provider_access, "Clinic"),
      check_pa(provider_access, "Mobile")
    ]

    check_pa_recursion(tails, result)
  end

  defp check_pa_recursion([], result), do: result

  defp validate_facility_level3(changeset) do
    benefits =
      changeset.changes.benefit
      |> benefit_codes_from_params()
    errors = Enum.map(Enum.with_index(changeset.changes.facility, 1), fn({x, index}) ->
      if String.downcase(x["coverage"]) == "acu" do
        validate_facility_level3_check_benefit(changeset, benefits, x, index)
      end
    end)

    errors =
      errors
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)

    if errors == [] do
      changeset
    else
      merge_changeset_errors(errors, changeset)
    end
  end

  defp validate_facility_level3_check_benefit(changeset, [], x, index), do: add_error(changeset, :benefit, "Benefit: Invalid Code/s")
  defp validate_facility_level3_check_benefit(changeset, benefits, x, index) do
    provider_access =
      benefits
      |> map_acu_benefit
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
      |> check_pa_recursion([])
      |> Enum.uniq()
      |> Enum.join(", ")

    for f <- x["code"] do
      facility = FacilityContext.get_facility_by_code(f)
      check_provider_access(changeset, facility.type.text, provider_access, index, f)
    end
  end

  defp map_acu_benefit(benefit) do
    benefit
    |> Enum.map(fn(x) ->
      record = get_benefit(x)
      _coverages = for bc <- record.benefit_coverages do
        check_acu_benefit(bc.coverage.name, record)
      end
    end)
  end

  defp check_provider_access(changeset, text, provider_access, index, f) do
    case text do
      "HOSPITAL-BASED" ->
        check_hb(changeset, provider_access, index, f)
      "CLINIC-BASED" ->
        check_cb(changeset, provider_access, index, f)
      "MOBILE" ->
        check_mobile(changeset, provider_access, index, f)
      _ ->
        nil
    end
  end

  defp check_acu_benefit(name, record) do
    if name == "ACU" do
      record
    end
  end

  defp check_hb(changeset, provider_access, index, f) do
    if provider_access =~ "Hospital" do
      nil
    else
      add_error(changeset, :"facility_row#{index}", "Provider Access: '#{f}' is not available due to acu benefit's provider access")
    end
  end

  defp check_cb(changeset, provider_access, index, f) do
    if not provider_access =~ "Clinic" do
      nil
    else
      add_error(changeset, :"facility_row#{index}", "Provider Access: '#{f}' is not available due to acu benefit's provider access")
    end
  end

  defp check_mobile(changeset, provider_access, index, f) do
    if provider_access =~ "Mobile" do
      nil
    else
      add_error(changeset, :"facility_row#{index}", "Provider Access: '#{f}' is not available due to acu benefit's provider access")
    end
  end

  defp validate_overall_coverage(changeset) do
    coverages = Enum.map(changeset.changes.coverage, fn(x) -> String.downcase x end)
    facility_coverages = for facility <- changeset.changes.facility do
      String.downcase(facility["coverage"])
    end

    result = coverages -- facility_coverages

    if result == [] do
      changeset
    else
      add_error(changeset, :facility, "Coverage #{result} is missing.")
    end
  end

  defp validate_duplicated_coverage(changeset) do
    coverages = for facility <- changeset.changes.facility do
      String.downcase facility["coverage"]
    end

    uniq_coverages = Enum.uniq(coverages)
    result = coverages -- uniq_coverages

    error_facilities = for {f, index} <- Enum.with_index(changeset.changes.facility, 1) do
      coverage = f["coverage"]
      if Enum.member?(result, String.downcase(coverage)) do
         add_error(changeset, :"facility_row#{index}", "Coverage: #{coverage} is duplicated")
      end
    end

    result =
      error_facilities
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

    if result == [] do
      changeset
    else
      merge_changeset_errors(result, changeset)
    end
  end

  defp validate_duplicated_facility_code(changeset) do
    errors = for {facility, index} <- Enum.with_index(changeset.changes.facility, 1) do
      if not is_nil(facility["code"]) do
        initial_facility = facility["code"]
        uniq_facility = Enum.uniq(facility["code"])
        result = initial_facility -- uniq_facility
        _error_facilities = for f <- changeset.changes.facility do
          _test = for x <- f["code"] do
            if Enum.member?(result, x) do
              add_error(changeset, :"facility_row#{index}", "Code: #{x} is duplicated")
            end
          end
        end
      end
    end

    errors =
      errors
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

    if errors == [] do
      changeset
    else
      merge_changeset_errors(errors, changeset)
    end
  end

  defp validate_duplicated_facility_location_group(changeset) do
    errors =
      for {facility, index} <- Enum.with_index(changeset.changes.facility, 1) do
        check_duplicate_location_group(facility["location_group"], index, changeset)
      end

    errors =
      errors
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

    if errors == [] do
      changeset
    else
      merge_changeset_errors(errors, changeset)
    end
  end

  defp check_duplicate_location_group(nil, index, changeset), do: nil
  defp check_duplicate_location_group([], index, changeset), do: nil
  defp check_duplicate_location_group(location_groups, index, changeset) do
    location_groups
    |> Enum.filter(fn(location_group) ->
        Enum.count(location_groups, &(&1 == location_group)) > 1
       end)
    |> Enum.uniq()
    |> Enum.map(&(add_error(changeset, :"facility_row#{index}", "Location Group: #{&1} is duplicated")))
  end

  ################################################# end of validation for facility_access

  ################################################# start of validation for funding_arrangement
  defp validate_funding_arrangement(changeset) do
    funding_records = changeset.changes[:funding_arrangement]
    coverages = Enum.map(changeset.changes[:coverage], fn(x) -> String.downcase x end)

    result = for {fr, index} <- Enum.with_index(funding_records, 1) do
      [
        check_funding_coverage(changeset, fr["coverage"], index, coverages),
        check_funding_type(changeset, fr["type"], index)
      ]
    end

    result =
      result
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

    if result == [] do
      validate_funding_arrangement_level2(changeset)
    else
      merge_changeset_errors(result, changeset)
    end

  end

  defp check_funding_type(changeset, type, index) do
    fa_type = ["aso", "full risk"]
    if not is_nil(type) do
      if not Enum.member?(fa_type, String.downcase(type)) do
        if type == "" do
          add_error(changeset, :"funding_arrangement_row#{index}", "Type: Empty strings are not accepted.")
        else
          add_error(changeset, :"funding_arrangement_row#{index}", "Type: '#{type}' is invalid, the only accepted type is ['ASO', 'Full Risk']")
        end
      end
    else
      add_error(changeset, :"funding_arrangement_row#{index}", "Type: Can't be blank.")
    end

  end

  defp check_funding_coverage(changeset, coverage, index, coverage_list) do
    if not is_nil(coverage) do
      if not Enum.member?(coverage_list, String.downcase coverage) do
        if coverage == "" do
          add_error(changeset, :"funding_arrangement_row#{index}", "Coverage: Empty strings are not accepted.")
        else
          add_error(changeset, :"funding_arrangement_row#{index}", "Coverage: '#{String.downcase coverage}' does not belong to available coverages of this plan.")
        end
      end
    else
      add_error(changeset, :"funding_arrangement_row#{index}", "Coverage: Can't be blank.")
    end

  end

  defp validate_funding_arrangement_level2(changeset) do
    _changeset =
      changeset
      |> validate_funding_overall_coverage()
      |> validate_funding_duplicated_coverage()
      |> transform_valid_casing_fa()
  end

  defp transform_valid_casing_fa(changeset) do
    funding_arrangement = changeset.changes[:funding_arrangement]
    result = for fa <- funding_arrangement do
      case String.downcase(fa["type"]) do
        "aso" ->
          %{
            "coverage" => fa["coverage"],
            "type" => "ASO"
          }
        "full risk" ->
          %{
            "coverage" => fa["coverage"],
            "type" => "Full Risk"
          }
      end
    end

    put_change(changeset, :funding_arrangement, result)
  end

  defp validate_funding_overall_coverage(changeset) do
    coverages = Enum.map(changeset.changes.coverage, fn(x) -> String.downcase x end)
    funding_arrangements = for facility <- changeset.changes.funding_arrangement do
      String.downcase facility["coverage"]
    end

   result = coverages -- funding_arrangements
    if result == [] do
      changeset
    else
      add_error(changeset, :funding_arrangement, "Coverage '#{result}' is missing.")
    end
  end

  defp validate_funding_duplicated_coverage(changeset) do
    coverages = for funding_arrangement <- changeset.changes.funding_arrangement do
      String.downcase funding_arrangement["coverage"]
    end

    uniq_coverages = Enum.uniq(coverages)
    result = coverages -- uniq_coverages

      error_funding = for {f, index} <- Enum.with_index(changeset.changes.funding_arrangement, 1) do
        coverage = String.downcase(f["coverage"])
        if Enum.member?(result, coverage) do
           add_error(changeset, :"funding_arrangement_row#{index}", "#{coverage} is duplicated")
        end
      end

    result =
      error_funding
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

    if result == [] do
      changeset
    else
      merge_changeset_errors(result, changeset)
    end
  end

  ################################################# end of validation for funding_arrangement

  def validate_risk_share(changeset) do
    risk_share = changeset.changes[:risk_share]
    if not is_nil(risk_share) do
      coverage_list = for coverage <- changeset.changes[:coverage], do: String.downcase(coverage)

      result = for {rs, index} <- Enum.with_index(risk_share, 1) do
        [
          check_rs_coverage(changeset, rs, index, coverage_list),
          check_rs_params(changeset, rs, index),
          if List.first(coverage_list) == "dentl" do
            check_rsf_dental_params(changeset, rs, index)
          else
            check_rsf_params(changeset, rs, index)
          end
        ]
      end

      result =
        result
        |> List.flatten
        |> Enum.uniq
        |> List.delete(nil)

      if result == [] do
        validate_risk_share_level2(changeset)
      else
        result_changeset = merge_changeset_errors(result, changeset)
        if result_changeset.valid? do
          validate_risk_share_level2(result_changeset)
        else
          result_changeset
        end
      end
    else
      changeset
    end

    # if result == [] do
    #   transform_valid_rs(changeset)
    # else
    #   result_changeset = merge_changeset_errors(result, changeset)
    #   if result_changeset.valid? do
    #     transform_valid_rs(changeset)
    #   else
    #     result_changeset
    #   end
    # end
  end

  defp validate_risk_share_level2(changeset) do
    risk_share = changeset.changes[:risk_share]
    rs_coverages = for rs <- risk_share, do: String.downcase(rs["coverage"])
    uniq_coverages = Enum.uniq(rs_coverages)
    result = rs_coverages -- uniq_coverages

    errors = for {rs, index} <- Enum.with_index(risk_share, 1) do
      coverage = String.downcase(rs["coverage"])
      if Enum.member?(result, coverage) do
        add_error(changeset, :"risk_share_row#{index}", "'#{coverage}' is duplicated.")
      else
        nil
      end
    end

    errors =
      errors
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

    if errors == [] do
      transform_valid_rs(changeset)
    else
      merge_changeset_errors(errors, changeset)
    end
  end

  defp transform_valid_rs(changeset) do
    risk_share = changeset.changes[:risk_share]
    result = for rs <- risk_share do

      valid_rs_af = transform_valid_rs_af(changeset, rs)

      valid_rs_naf = transform_valid_rs_naf(changeset, rs)

      _valid_rs_naf = if Map.has_key?(valid_rs_naf, "exempted_facilities") do
        Map.put(valid_rs_naf, "exempted_facilities", transform_valid_ef(valid_rs_naf["exempted_facilities"]))
      else
        valid_rs_naf
      end
    end

    put_change(changeset, :risk_share, result)
  end

  defp transform_valid_rs_af(changeset, rs) do
    if Map.has_key?(rs, "af_type") do
      case String.downcase(rs["af_type"]) do
        "coinsurance" ->
          Map.put(rs, "af_type", "CoInsurance")
        "copayment" ->
          Map.put(rs, "af_type", "Copayment")
        "" ->
          Map.put(rs, "af_type", "N/A")
      end
    else
      rs
    end
  end

  defp transform_valid_rs_naf(changeset, rs) do
    if Map.has_key?(rs, "naf_type") do
      case String.downcase(rs["naf_type"]) do
        "coinsurance" ->
          Map.put(rs, "naf_type", "CoInsurance")
        "copayment" ->
          Map.put(rs, "naf_type", "Copayment")
        "" ->
          Map.put(rs, "naf_type", "N/A")
      end
    else
      rs
    end
  end

  defp transform_valid_ef(ef) do
    for e <- ef do
      valid_rsf = if Map.has_key?(e, "type") do
        case String.downcase(e["type"]) do
          "coinsurance" ->
            Map.put(e, "type", "CoInsurance")
          "copayment" ->
            Map.put(e, "type", "Copayment")
        end
      else
        e
      end

      _valid_rsf = if Map.has_key?(valid_rsf, "exempted_procedures") do
        Map.put(valid_rsf, "exempted_procedures", transform_valid_rsfp(e["exempted_procedures"]))
      else
        valid_rsf
      end
    end
  end

  defp transform_valid_rsfp(efp) do
    for e <- efp do
      _valid_rsf = if Map.has_key?(e, "type") do
        case String.downcase(e["type"]) do
          "coinsurance" ->
            Map.put(e, "type", "CoInsurance")
          "copayment" ->
            Map.put(e, "type", "Copayment")
        end
      else
        e
      end
    end
  end

  defp check_rs_coverage(changeset, rs, index, coverage_list) do
    if Map.has_key?(rs, "coverage") do
      coverage = String.downcase(rs["coverage"])
      if not Enum.member?(coverage_list, coverage) do
        if coverage == "" do
          add_error(changeset, :"risk_share_row#{index}", "Empty strings are not accepted.")
        else
          add_error(changeset, :"risk_share_row#{index}", "'#{coverage}' does not belong to available coverages of this plan.")
        end
      end
    else
      add_error(changeset, :"risk_share_row#{index}", "Coverage is required in a risk share.")
    end
  end

  defp check_rs_params(changeset, rs, index) do
    valid_keys = [
      "af_type",
      "af_value",
      "af_covered",
      "naf_reimbursable",
      "naf_type",
      "naf_value",
      "naf_covered",
      "asdf_type",
      "asdf_value",
      "asdf_special_handling"
    ]

    rs_keys = Map.keys(rs)

    result = for k <- rs_keys, do: if Enum.member?(valid_keys, k), do: k

    result =
      result
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

    if result == [] do
      nil
    else

      errors = [
        check_rs_type(changeset, rs, index, "af"),
        check_rs_type(changeset, rs, index, "naf"),
        check_rs_value(changeset, rs, index, "af"),
        check_rs_value(changeset, rs, index, "naf"),
        check_rs_value(changeset, rs, index, "asdf"),
        check_rs_covered(changeset, rs, index, "af"),
        check_rs_covered(changeset, rs, index, "naf"),
        check_rs_reimbursable(changeset, rs, index),
        check_rs_special_handling(changeset, rs, index, "asdf")
      ]

      if rs["coverage"] == "DENTL", do: errors = errors ++ [check_rs_type(changeset, rs, index, "asdf")]

      errors =
        errors
        |> List.flatten
        |> Enum.uniq
        |> List.delete(nil)

      if errors == [] do
        nil
      else
        merge_changeset_errors(errors, changeset)
      end
    end
  end

  defp check_rs_special_handling(changeset, rs, index, type) do
    field = "#{type}_special_handling"
    if Map.has_key?(rs, field) do
      value = String.downcase(rs[field])
      valid_list = ["corporate guarantee", "aso override", "fee for service", "member pays"]
      if not Enum.member?(valid_list, value) do
        if value == "" do
          add_error(changeset, :"risk_share_row#{index}", "#{field}: Empty String are not accepted.")
        else
          add_error(changeset, :"risk_share_row#{index}", "#{field}: '#{value}' is not valid. Please only select 'ASO Override', 'Fee for Service', 'Member Pays', and 'Corporate Guarantee'.")
        end
      end
    else
      if rs["coverage"] == "DENTL" do
        add_error(changeset, :risk_share, "Special Handling can't be blank")
      else
        changeset
      end
    end
  end

  defp check_rs_type(changeset, rs, index, type) do
    field = "#{type}_type"
    if Map.has_key?(rs, field) do
      value = String.downcase(rs[field])
      valid_list = ["copayment", "coinsurance"]
      if not Enum.member?(valid_list, value) do
        if value == "" do
          add_error(changeset, :"risk_share_row#{index}", "#{field}: Empty String are not accepted.")
        else
          add_error(changeset, :"risk_share_row#{index}", "#{field}: '#{value}' is not valid. Please only select between an empty string, 'Copayment', and 'CoInsurance'.")
        end
      end
    else
      if field == "asdf_type" do
        add_error(changeset, :risk_share, "risk share type can't be blank")
      else
        changeset
      end
    end
  end

  defp check_rs_value(changeset, rs, index, type) do
    field_type = "#{type}_type"
    field = "#{type}_value"
    if Map.has_key?(rs, field) do

      case Map.has_key?(rs, field_type) do
        true ->
          value = rs[field]
          case String.downcase(rs[field_type]) do
            "copayment" ->
              check_rs_value_copayment(changeset, field, value, index)
            "coinsurance" ->
              check_rs_value_coinsurance(changeset, field, value, index)
            "" ->
            add_error(changeset, :"risk_share_row#{index}", "#{field_type}: Empty String are not accepted.")
            _ ->
              nil
          end
        _ ->

          add_error(changeset, :"risk_share_row#{index}", "You need to have '#{field_type}' first before using '#{field}'")
      end ### end of case

    else
      check_rs_value_lvl2(changeset, rs, index, type)
      #nil
    end

  end

  defp check_rs_value_copayment(changeset, field, value, index) do
    cond do
      field == "" ->
        add_error(changeset, :"risk_share_row#{index}", "#{field}: Empty string are not accepted.")
      validate_decimal(value) == false ->
        add_error(changeset, :"risk_share_row#{index}", "#{field}: '#{value}' is not a valid amount.")
      true ->
        nil
    end
  end

  defp check_rs_value_coinsurance(changeset, field, value, index) do
    cond do
      validate_numbers(value) == false ->
        add_error(changeset, :"risk_share_row#{index}", "#{field}: '#{value}' is not a valid number.")
      validate_numbers(value) ==  true ->
        if value == "" do
          add_error(changeset, :"risk_share_row#{index}", "#{field}: Empty string are not accepted.")
        else
          {value, _} = Float.parse(value)
          val_decimal = Decimal.new(value)
          total = Decimal.new("100")
          result = Decimal.compare(total, val_decimal)

          if result == Decimal.new(1) or result == Decimal.new(0) do
            nil
          else
            add_error(changeset, :"risk_share_row#{index}", "#{field}: '#{value}' should be greater than zero, and less than or equal to one hundred.")
          end

          # value_int = String.to_integer(value)
          # if value_int <= 100 and value_int > 0 do
          #   nil
          # else
          #   add_error(changeset, :"risk_share_row#{index}", "#{field}: '#{value}' should be greater than zero, and less than or equal to one hundred.")
          # end
        end
      true ->
        nil
    end
  end

  defp check_rs_value_lvl2(changeset, rs, index, type) do
    field_type = "#{type}_type"
    field = "#{type}_value"
    if Map.has_key?(rs, field_type) do
      if rs[field_type] != "" do
        add_error(changeset, :"risk_share_row#{index}", "'#{field}' is necessary in a risk share.")
      else
        nil
      end
    else
      nil
    end

  end

  defp check_rs_covered(changeset, rs, index, type) do
    field = "#{type}_covered"
    if Map.has_key?(rs, field) do
      value = rs[field]
      if not validate_numbers(value) do
        add_error(changeset, :"risk_share_row#{index}", "#{field}: '#{value}' is not a valid number.")
      else
        value_int = String.to_integer(value)
        if value_int <= 100 and value_int > 0 do
          nil
        else
          add_error(changeset, :"risk_share_row#{index}", "#{field}: '#{value}' should be greater than zero, and less than or equal to one hundred.")
        end
      end
    else
      if rs["coverage"] != "DENTL" do
        add_error(changeset, :"risk_share_row#{index}", "'#{field}' is necessary in a risk share.")
      end
    end
  end

  defp check_rs_reimbursable(changeset, rs, index) do
    field = "naf_reimbursable"
    if Map.has_key?(rs, field) do
      value = String.downcase(rs[field])
      if not Enum.member?(["yes", "no"], value) do
        add_error(changeset, :"risk_share_row#{index}", "#{field}: '#{value}' is not valid. Please only select between 'Yes' or 'No'.")
      end
    else
      if rs["coverage"] != "DENTL" do
        add_error(changeset, :"risk_share_row#{index}", "'#{field}' is necessary in a risk share.")
      end
    end
  end

  defp check_rsf_params(changeset, rs, index) do
    if Map.has_key?(rs, "exempted_facilities") do
      rs_data = %{}
      rs_general_types = %{exempted_facilities: {:array, :map}}

      rs_changeset =
        {rs_data, rs_general_types}
        |> cast(rs, Map.keys(rs_general_types))
        |> validate_required([:exempted_facilities])

      if rs_changeset.valid? do
        exempted_facilities = rs_changeset.changes[:exempted_facilities]
        if exempted_facilities != [] do
          result = for {ef, ef_index} <- Enum.with_index(exempted_facilities, 1), do: validate_ef(
            changeset, ef, index, ef_index)

          result =
            result
            |> List.flatten
            |> Enum.uniq
            |> List.delete(nil)

          if result == [] do
            changeset
          else
            merge_changeset_errors(result, changeset)
          end
        end
      else
        add_error(changeset, :"risk_share_row#{index}", "Exempted facilities is not valid. It should be an array map.")
      end
    end
  end

  defp check_rsf_dental_params(changeset, rs, index) do
    if Map.has_key?(rs, "exempted_facilities") do
      rs_data = %{}
      rs_general_types = %{exempted_facilities: {:array, :map}}

      rs_changeset =
        {rs_data, rs_general_types}
        |> cast(rs, Map.keys(rs_general_types))
        |> validate_required([:exempted_facilities])

      if rs_changeset.valid? do
        exempted_facilities = rs_changeset.changes[:exempted_facilities]
        if exempted_facilities != [] do
          rsf_changeset = validate_duplicated_rs_facility_code(changeset, rs_changeset, index, exempted_facilities)
          if rsf_changeset.valid? do
            result = for {ef, ef_index} <- Enum.with_index(exempted_facilities, 1), do: validate_ef_dental(
              changeset, ef, index, ef_index)

              result =
                result
                |> List.flatten
                |> Enum.uniq
                |> List.delete(nil)

              if result == [] do
                changeset
              else
                merge_changeset_errors(result, changeset)
              end
          else
            rsf_changeset
          end
        end
      else
        add_error(changeset, :"risk_share_row#{index}", "Exempted facilities is not valid. It should be an array map.")
      end
    end
  end

  defp validate_duplicated_rs_facility_code(changeset, rs_changeset, index, exempted_facilities) do
    errors = for {facility, index} <- Enum.with_index(exempted_facilities, 1) do
      if not is_nil(facility["facility_code"]) do
        initial_facilities =
          exempted_facilities
          |> Enum.map(&(&1["facility_code"]))
        uniq_facility = initial_facilities |> Enum.uniq()
        result = initial_facilities -- uniq_facility
        Enum.map(exempted_facilities, fn(f) ->
          x = f["facility_code"]
          validate_duplicated_rs_fc(changeset, index, result, x)
        end)
      end
    end

    errors =
      errors
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

    if errors == [] do
      validate_exempted_rs_facility_code(changeset, rs_changeset, index, exempted_facilities)
      # rs_changeset
    else
      merge_changeset_errors(errors, rs_changeset)
    end
  end

  defp validate_duplicated_rs_fc(changeset, index, result, x) do
    if Enum.member?(result, x) do
      add_error(changeset, :"facility_row#{index}", "Code: #{x} is duplicated")
    end
  end

  defp validate_exempted_rs_facility_code(changeset, rs_changeset, index, exempted_facilities) do
    facility = List.first(changeset.changes.facility)
    case facility["type"] do
      "exception" ->
        validate_exempted_rs_facility_code2(changeset, rs_changeset, index, exempted_facilities, facility)
      "inclusion" ->
        rs_changeset
      _ ->
        add_error(changeset, :facility, "Type is invalid")
    end
  end

  defp validate_exempted_rs_facility_code2(changeset, rs_changeset, index, exempted_facilities, facility) do
    code = Enum.map(facility["code"], &(&1))
    ef_codes = Enum.map(exempted_facilities, &(&1["facility_code"]))

    errors = for {ef_code, index} <- Enum.with_index(ef_codes, 1) do
      if Enum.member?(code, ef_code) do
        add_error(rs_changeset, :"facility_row#{index}", "Code: #{ef_code} is an exempted facility")
      end
    end

    errors =
      errors
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

    if errors == [] do
      rs_changeset
    else
      merge_changeset_errors(errors, rs_changeset)
    end
  end

  defp validate_ef_fields(changeset, field, index, ef_index) do
    if not Map.has_key?(changeset.changes, field) do
      add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: #{field} is necessary for an exempted facility.")
    else
      changeset
    end
  end

  defp validate_ef(changeset, exempted_facility, index, ef_index) do
    if exempted_facility != %{} do
      rsf_data = %{}
      rsf_general_types = %{
        covered: :string,
        type: :string,
        value: :string,
        facility_code: :string,
        exempted_procedures: {:array, :map}
      }

      rsf_changeset =
        {rsf_data, rsf_general_types}
        |> cast(exempted_facility, Map.keys(rsf_general_types))
        |> validate_ef_fields(:covered, index, ef_index)
        |> validate_ef_fields(:type, index, ef_index)
        |> validate_ef_fields(:value, index, ef_index)
        |> validate_ef_fields(:facility_code, index, ef_index)
        #  |> validate_required([
        #    :covered,
        #    :type,
        #    :value,
        #    :facility_code,
        #    :exempted_procedures
        #  ])

      if rsf_changeset.valid? do
        rsf_changeset =
          rsf_changeset
          |> validate_facility_code(index, ef_index)
          |> validate_rs_param_covered(index, ef_index)
          |> validate_rs_param_value(index, ef_index)
          |> validate_rs_param_type(index, ef_index)

        if rsf_changeset.valid? do
          if Map.has_key?(rsf_changeset.changes, :exempted_procedures) do
            validate_rsf_params(
              changeset,
              rsf_changeset.changes[:exempted_procedures],
              index,
              ef_index,
              rsf_changeset.changes[:facility_code]
            )
          end
        else
          merge_changeset_errors([rsf_changeset], changeset)
        end
      else
        merge_changeset_errors([rsf_changeset], changeset)
      end
    else
      add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Invalid parameters.")
    end
  end

  defp validate_ef_dental(changeset, exempted_facility, index, ef_index) do
    if exempted_facility != %{} do
      rsf_data = %{}
      rsf_general_types = %{
        sdf_type: :string,
        sdf_value: :string,
        facility_code: :string,
        sdf_special_handling: :string,
      }

      rsf_changeset =
        {rsf_data, rsf_general_types}
        |> cast(exempted_facility, Map.keys(rsf_general_types))
        |> validate_ef_fields(:sdf_type, index, ef_index)
        |> validate_ef_fields(:sdf_value, index, ef_index)
        |> validate_ef_fields(:facility_code, index, ef_index)
        |> validate_ef_fields(:sdf_special_handling, index, ef_index)

      if rsf_changeset.valid? do
        rsf_changeset =
          rsf_changeset
          |> validate_dental_facility_code(changeset, index, ef_index)
          |> validate_rs_dental_param_value(index, ef_index)
          |> validate_rs_dental_param_type(index, ef_index)
          |> validate_rs_dental_param_sh(index, ef_index)

        if rsf_changeset.valid? do
          if Map.has_key?(rsf_changeset.changes, :exempted_procedures) do
            validate_rsf_params(
              changeset,
              rsf_changeset.changes[:exempted_procedures],
              index,
              ef_index,
              rsf_changeset.changes[:facility_code]
            )
          end
        else
          merge_changeset_errors([rsf_changeset], changeset)
        end
      else
        merge_changeset_errors([rsf_changeset], changeset)
      end
    else
      add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Invalid parameters.")
    end
  end

  defp validate_dental_facility_code(changeset, dental_changeset, index, ef_index) do
    validate_dental_facility_rs(dental_changeset, changeset, index, ef_index)
  end

  defp validate_dental_facility_rs(changeset, rs_changeset, index, ef_index) do
    facility_rec = changeset.changes[:facility]
    fc = facility_rec
         |> List.first()

    cond do
      fc["type"] == "exception" && Map.has_key?(fc, "location_group") ->
        lg =
          facility_rec
          |> Enum.map(&(&1["location_group"]))
          |> List.flatten()
          |> List.first()

          lg1 = MainProductContext.get_dental_facilities_by_lg_name(lg)

          if is_nil(lg1) do
            add_error(rs_changeset, :risk_share, "Location group does not have a dental facility type")
          else
            validate_dental_facility2_rs(rs_changeset, lg1, rs_changeset, index, ef_index)
          end

      fc["type"] == "exception" && not Map.has_key?(fc, "location_group") ->
        add_error(rs_changeset, :risk_share, "Location group is required for setup")

      fc["type"] == "inclusion" ->
        df = rs_changeset.changes[:facility_code]
        dfc =
          changeset.changes[:facility]
          |> Enum.map(&(&1["code"]))
          |> List.flatten()

        if Enum.member?(dfc, df) do
          rs_changeset
        else
          add_error(rs_changeset, :exempted_facilities, "one or more facility code is not included in specific dental facilities")
        end
      true ->
        add_error(rs_changeset, :risk_share, "Facility coverage type does not exist!")
    end
  end

  defp validate_dental_facility2_rs(changeset, lg1, rs_changeset, index, ef_index) do
    dlgfc = Enum.map(lg1.facility_location_group, &(&1.facility.code))
    fc = rs_changeset.changes[:facility_code]

    if not Enum.member?(dlgfc, fc) do
      if fc == "" do
        add_error(rs_changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Empty String is not allowed.")
      else
        add_error(rs_changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: '#{fc}' does not belong to the selected location group")
      end
    else
      rs_changeset
    end
  end

  defp validate_facility_code(changeset, index, ef_index) do
    facility_code = changeset.changes[:facility_code]
    facility = get_facility(facility_code)

    if is_nil(facility) do
      if facility_code == "" do
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Empty String is not allowed.")
      else
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: '#{facility_code}' does not exist.")
      end
    else
      changeset
    end
  end

  defp get_facility(code) do
    Facility
    |> where([f], ilike(f.code, ^code))
    |> Repo.one
    |> Repo.preload([:facility_payor_procedures])
  end

  defp validate_rs_param_covered(changeset, index, ef_index) do
    covered = changeset.changes[:covered]
    if not validate_numbers(covered) do
      if covered == "" do
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Empty String is not allowed.")
      else
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: '#{covered}' is not valid number.")
      end
    else
      value_int = String.to_integer(covered)
      if value_int <= 100 and value_int > 0 do
        changeset
      else
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: '#{covered}' should be greater than zero, and less than or equal to one hundred.")
      end
    end
  end

  defp validate_rs_dental_param_type(changeset, index, ef_index) do
    type = changeset.changes[:sdf_type]
    valid_types = ["copayment", "coinsurance"]

    if not Enum.member?(valid_types, String.downcase(type)) do
      if type == "" do
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Empty String is not allowed.")
      else
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: '#{type}' is invalid. Please only select between 'Copayment' and 'CoInsurance'.")
      end
    else
      changeset
    end
  end

  defp validate_rs_dental_param_value(changeset, index, ef_index) do
    type = changeset.changes[:sdf_type]
    valid_types = ["copayment", "coinsurance"]

    if Enum.member?(valid_types, String.downcase(type)) do
      value = changeset.changes[:sdf_value]
      if value != "" do
        case String.downcase(type) do
          "copayment" ->
            validate_rpv_copayment(changeset, value, index, ef_index)
          "coinsurance" ->
            validate_rpv_coinsurance(changeset, value, index, ef_index)
          _ ->
            changeset
        end
      else
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Empty string is now allowed.")
      end
    else
      changeset
    end
  end

  defp validate_rs_dental_param_sh(changeset, index, ef_index) do
    special_handling = changeset.changes[:sdf_special_handling]
    valid_sh = ["corporate guarantee", "aso override", "fee for service", "member pays"]

    if not Enum.member?(valid_sh, String.downcase(special_handling)) do
      if special_handling == "" do
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Empty String is not allowed.")
      else
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: '#{special_handling}' is invalid. Please only select between 'Corporate Guarantee', 'ASO Override', 'Fee for Service', and 'Member Pays'.")
      end
    else
      changeset
    end
  end

  defp validate_rpv_copayment(changeset, value, index, ef_index) do
    # Validate Risk Share Param Value Copayment

    if not validate_decimal(value) do
      add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: '#{value}' is not a valid amount.")
    else
      changeset
    end
  end

  defp validate_rpv_coinsurance(changeset, value, index, ef_index) do
    # Validate Risk Share Param Value CoInsurance

    if not validate_numbers(value) do
      add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: '#{value}' is not a valid amount.")
    else
      {value, _} = Float.parse(value)
      val_decimal = Decimal.new(value)
      total = Decimal.new("100")
      result = Decimal.compare(total, val_decimal)

      if result == Decimal.new(1) or result == Decimal.new(0) do
        changeset
      else
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: '#{value}' should be greater than zero, and less than or equal to one hundred.")
      end
    end
  end


  defp validate_rs_param_type(changeset, index, ef_index) do
    type = changeset.changes[:type]
    valid_types = ["copayment", "coinsurance"]

    if not Enum.member?(valid_types, String.downcase(type)) do
      if type == "" do
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Empty String is not allowed.")
      else
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: '#{type}' is invalid. Please only select between 'Copayment' and 'CoInsurance'.")
      end
    else
      changeset
    end
  end

  defp validate_rs_param_value(changeset, index, ef_index) do
    type = changeset.changes[:type]
    valid_types = ["copayment", "coinsurance"]

    if Enum.member?(valid_types, String.downcase(type)) do
      value = changeset.changes[:value]
      if value != "" do
        case String.downcase(type) do
          "copayment" ->
            validate_rpv_copayment(changeset, value, index, ef_index)
          "coinsurance" ->
            validate_rpv_coinsurance(changeset, value, index, ef_index)
          _ ->
            changeset
        end
      else
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Empty string is now allowed.")
      end
    else
      changeset
    end
  end

#   defp validate_rpv_copayment(changeset, value, index, ef_index) do
#     # Validate Risk Share Param Value Copayment

#     if not validate_decimal(value) do
#       add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: '#{value}' is not a valid amount.")
#     else
#       changeset
#     end
#   end

#   defp validate_rpv_coinsurance(changeset, value, index, ef_index) do
#     # Validate Risk Share Param Value CoInsurance

#     if not validate_numbers(value) do
#       add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: '#{value}' is not a valid amount.")
#     else
#       value_int = String.to_integer(value)
#       if value_int <= 100 and value_int > 0 do
#         changeset
#       else
#         add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: '#{value}' should be greater than zero, and less than or equal to one hundred.")
#       end
#     end
#   end

  defp validate_rsf_params(changeset, rsfp_params, index, ef_index, facility_code) do
    result = for {rsfp, rsfp_index} <- Enum.with_index(rsfp_params, 1) do
      params = %{
        changeset: changeset,
        index: index,
        ef_index: ef_index,
        rsfp: rsfp,
        rsfp_index: rsfp_index,
        facility_code: facility_code
      }
      validate_rsfp_params(params)

      #  [
      #    validate_rsfp_facility_cpt_code(changeset, index, ef_index, rsfp_index),
      #    validate_rsfp_covered(changeset, index, ef_index, rsfp_index),
      #    validate_rsfp_type(changeset, index, ef_index, rsfp_index),
      #    validate_rsfp_value(changeset, index, ef_index, rsfp_index)
      #  ]
    end

    result =
      result
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

    if result == [] do
      changeset
    else
      merge_changeset_errors(result, changeset)
    end
  end

  defp validate_rsfp_fields(changeset, field, index, ef_index, rsfp_index) do
    if not Map.has_key?(changeset.changes, field) do
      add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Exempted Procedure Row #{rsfp_index}: #{field} is necessary for an exempted procedure.")
    else
      changeset
    end
  end

  defp validate_rsfp_params(params) do

    global_changeset = params.changeset
    index = params.index
    ef_index = params.ef_index
    rsfp = params.rsfp
    rsfp_index = params.rsfp_index
    facility_code = params.facility_code

    if rsfp != %{} do
      rsfp_data = %{}
      rsfp_general_types = %{
        covered: :string,
        type: :string,
        value: :string,
        facility_cpt_code: :string
      }

      rsfp_changeset =
        {rsfp_data, rsfp_general_types}
        |> cast(
          rsfp,
          Map.keys(rsfp_general_types)
        )
        |> validate_rsfp_fields(:covered, index, ef_index, rsfp_index)
        |> validate_rsfp_fields(:type, index, ef_index, rsfp_index)
        |> validate_rsfp_fields(:value, index, ef_index, rsfp_index)
        |> validate_rsfp_fields(:facility_cpt_code, index, ef_index, rsfp_index)
        #  |> validate_required([
        #    :covered,
        #    :type,
        #    :value,
        #    :facility_cpt_code
        #  ]

      if rsfp_changeset.valid? do
        rsfp_changeset =
          rsfp_changeset
          |> validate_rsfp_covered(index, ef_index, rsfp_index)
          |> validate_rsfp_type(index, ef_index, rsfp_index)
          |> validate_rsfp_value(index, ef_index, rsfp_index)
          |> validate_rsfp_fcc(index, ef_index, rsfp_index, facility_code)
          if rsfp_changeset.valid? do
            global_changeset
          else
            merge_changeset_errors([rsfp_changeset], global_changeset)
          end
      else
        merge_changeset_errors([rsfp_changeset], global_changeset)
      end

    else
      add_error(global_changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Exempted Procedure Row #{rsfp_index}: Invalid Parameters.")
    end
  end

  defp validate_rsfp_covered(changeset, index, ef_index, rsfp_index) do
    covered = changeset.changes[:covered]
    if not validate_numbers(covered) do
      if covered == "" do
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Exempted Procedure Row #{rsfp_index}: Empty string is now allowed.")
      else
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Exempted Procedure Row #{rsfp_index}: #{covered} is not a valid number.")
      end
    else
      value_int = String.to_integer(covered)
      if value_int <= 100 and value_int > 0 do
        changeset
      else
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Exempted Procedure Row #{rsfp_index}: #{covered} should be greater than zero, and less than or equal to one hundred.")
      end
    end
  end

  defp validate_rsfp_type(changeset, index, ef_index, rsfp_index) do
    type = changeset.changes[:type]
    valid_types = ["copayment", "coinsurance"]

    if not Enum.member?(valid_types, String.downcase(type)) do
      if type == "" do
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Exempted Procedure Row #{rsfp_index}: Empty string is now allowed.")
      else
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Exempted Procedure Row #{rsfp_index}: '#{type}' is invalid. Please only select between 'Copayment' and 'CoInsurance'.")
      end
    else
      changeset
    end
  end

  defp validate_rsfp_value(changeset, index, ef_index, rsfp_index) do
    type = changeset.changes[:type]
    valid_types = ["copayment", "coinsurance"]

    if Enum.member?(valid_types, String.downcase(type)) do
      value = changeset.changes[:value]
      if value != "" do
        case String.downcase(type) do
          "copayment" ->
            check_rsfp_val_copayment(changeset, value, index, ef_index, rsfp_index)
          "coinsurance" ->
            check_rsfp_val_coinsurance(changeset, value, index, ef_index, rsfp_index)
          _ ->
            changeset
        end
      else
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Exempted Procedure Row #{rsfp_index}: Empty string is now allowed.")
      end
    else
      changeset
    end
  end

  defp check_rsfp_val_copayment(changeset, value, index, ef_index, rsfp_index) do
    if not validate_decimal(value) do
      add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Exempted Procedure Row #{rsfp_index}: '#{value}' is not a valid amount.")
    else
      changeset
    end
  end

  defp check_rsfp_val_coinsurance(changeset, value, index, ef_index, rsfp_index) do
    if not validate_numbers(value) do
      add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Exempted Procedure Row #{rsfp_index}: '#{value}' is not a valid number.")
    else
      value_int = String.to_integer(value)
      if value_int <= 100 and value_int > 0 do
        changeset
      else
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Exempted Procedure Row #{rsfp_index}: '#{value}' should be greater than zero, and less than or equal to one hundred.")
      end
    end
  end

  defp validate_rsfp_fcc(changeset, index, ef_index, rsfp_index, facility_code) do
    facility = get_facility(facility_code)
    fpp = changeset.changes[:facility_cpt_code]
    valid_procedures = for p <- facility.facility_payor_procedures do
      String.downcase(p.code)
    end

    if Enum.member?(valid_procedures, String.downcase(fpp)) do
      changeset
    else
      if fpp == "" do
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Exempted Procedure Row #{rsfp_index}: Empty string is now allowed.")
      else
        add_error(changeset, :"risk_share_row#{index}", "Exempted Facility Row #{ef_index}: Exempted Procedure Row #{rsfp_index}: #{fpp} doesn't belong to valid procedures of the #{facility_code}.")
      end
    end
  end

  defp validate_rnb(changeset) do

    rnb = changeset.changes[:rnb]
    product_base = String.downcase(changeset.changes[:product_base])
    valid_rnb_coverage = if product_base == "benefit-based" do
      ["mtrnty", "acu", "ip"]
    else
      ["mtrnty", "ip"]
    end
    coverage_list = for coverage <- changeset.changes[:coverage] do
      if Enum.member?(valid_rnb_coverage, String.downcase(coverage)) do
        String.downcase(coverage)
      end
    end

    if not is_nil(rnb) do
      coverage_in_params = for r <- rnb, do: String.downcase(r["coverage"])

      result = (coverage_list -- coverage_in_params) |> Enum.uniq() |> List.delete(nil)

      if result == [] do
        validate_rnb_level_1(changeset)
      else
        errors = validate_rnb_level1_1(changeset, result)

        if Enum.empty?(errors) do
          validate_rnb_level_1(changeset)
        else
          merge_changeset_errors(errors, changeset)
        end
      end
    else
      errors = validate_rnb_level1_1(changeset, coverage_list)
      merge_changeset_errors(errors, changeset)
    end
  end

  defp validate_rnb_level_1(changeset) do
    # Validates Room and Board records.

    rnb = changeset.changes[:rnb]
    coverage_list = for coverage <- changeset.changes[:coverage], do: String.downcase(coverage)

    result = for {r, index} <- Enum.with_index(rnb, 1) do
      [
        check_rnb_coverage(changeset, r, index, coverage_list),
        check_rnb_type(changeset, r, index)
      ]
    end

    result =
      result
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

    if result == [] do
      validate_rnb_level2(changeset)
    else
      merge_changeset_errors(result, changeset)
    end
  end

  defp validate_rnb_level2(changeset) do
    rnb = changeset.changes[:rnb]
    result = for {r, index} <- Enum.with_index(rnb, 1) do
      [
        check_rt(changeset, r, index),
        check_rla(changeset, r, index),
        check_ru(changeset, r, index),
        check_rut(changeset, r, index)
      ]
    end

    result =
      result
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

    if result == [] do
      validate_rnb_level4(changeset)
    else
      merge_changeset_errors(result, changeset)
    end
  end

  defp check_type_coverage([head | tails], result) do
    acu_type = head.acu_type
    acu_coverage = head.acu_coverage
    val = if acu_type == "Executive" and acu_coverage == "Inpatient" do
      true
    end

    result = result ++ [val]
    check_type_coverage(tails, result)
  end

  defp check_type_coverage([], result), do: result

  defp validate_rnb_level1_1(changeset, result) do
    result =
      result
      |> Enum.uniq()
      |> List.delete(nil)

    for r <- result do
      if r == "acu" do
        benefit_codes =
          changeset.changes.benefit
          |> benefit_codes_from_params()
        acu_benefit = for b <- benefit_codes do
          record = get_benefit(b)
          _coverages = for bc <- record.benefit_coverages do
            if bc.coverage.name == "ACU" do
              record
            end
          end
        end
        acu_benefit =
          acu_benefit
          |> List.flatten
          |> Enum.uniq
          |> List.delete(nil)
          |> check_type_coverage([])

        if Enum.member?(acu_benefit, true) do
          add_error(changeset, :rnb, "Room and board is missing a coverage, '#{r}'")
        end
      else
        add_error(changeset, :rnb, "Room and board is missing a coverage, '#{r}'")
      end
    end
    |> List.flatten
    |> Enum.uniq
    |> List.delete(nil)
  end

  # defp check_rnb_acu(acu_benefit) do
  #   raise acu_benefit
  # end

  defp validate_rnb_level4(changeset) do
    _changeset =
      changeset
      |> validate_rnb_duplicate_coverage()
      |> transform_valid_casing_rnb()
  end

  defp transform_valid_casing_rnb(changeset) do
    rnb = changeset.changes[:rnb]
    result = for r <- rnb do
      case String.downcase(r["room_and_board"]) do
        "alternative" ->
          %{
            "coverage" => r["coverage"],
            "room_and_board" => "Alternative",
            "room_type" => r["room_type"],
            "room_limit_amount" => r["room_limit_amount"],
            "room_upgrade" => r["room_upgrade"],
            "room_upgrade_time" => transform_rut(r["room_upgrade_time"])
          }
        "nomenclature" ->
          %{
            "coverage" => r["coverage"],
            "room_and_board" => "Nomenclature",
            "room_type" => r["room_type"],
            "room_limit_amount" => r["room_limit_amount"],
            "room_upgrade" => r["room_upgrade"],
            "room_upgrade_time" => transform_rut(r["room_upgrade_time"])
          }
        "peso based" ->
          %{
            "coverage" => r["coverage"],
            "room_and_board" => "Peso Based",
            "room_type" => r["room_type"],
            "room_limit_amount" => r["room_limit_amount"],
            "room_upgrade" => r["room_upgrade"],
            "room_upgrade_time" => transform_rut(r["room_upgrade_time"])
          }
      end
    end

    put_change(changeset, :rnb, result)
  end

  defp transform_rut(rut) do
    value = String.downcase(rut)
    case value do
      "hours" ->
        "Hours"
      "days" ->
        "Days"
    end
  end

  defp validate_rnb_duplicate_coverage(changeset) do
    rnb = changeset.changes[:rnb]
    product_base = String.downcase(changeset.changes[:product_base])
    coverage_in_params = for r <- rnb, do: String.downcase(r["coverage"])
    valid_rnb_coverage = if product_base == "benefit-based" do
      ["mtrnty", "acu", "ip"]
    else
      ["mtrnty", "ip"]
    end

    coverage_list = for coverage <- changeset.changes[:coverage] do
      if Enum.member?(valid_rnb_coverage, String.downcase(coverage)) do
        String.downcase(coverage)
      end
    end

    _result = coverage_list -- coverage_in_params |> Enum.uniq() |> List.delete(nil)

    rnb_coverages =
      rnb
      |> Enum.map(fn(x) -> String.downcase(x["coverage"]) end)

    uniq_rnb_coverages =
      rnb
      |> Enum.map(fn(x) -> String.downcase(x["coverage"]) end)
      |> Enum.uniq()

    result = rnb_coverages -- uniq_rnb_coverages

    error_rnb = for {rnb, index} <- Enum.with_index(changeset.changes.rnb, 1) do
      coverage = rnb["coverage"]
      if Enum.member?(result, String.downcase(coverage)) do
        add_error(changeset, :"rnb#{index}", "#{String.downcase(coverage)} is duplicated")
      end
    end

    result =
      error_rnb
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

    if result == [] do
      changeset
    else
      merge_changeset_errors(result, changeset)
    end

  end

  defp check_rnb_coverage(changeset, rnb, index, coverage_list) do
    if Map.has_key?(rnb, "coverage") do
      coverage = rnb["coverage"]
      if not Enum.member?(coverage_list, String.downcase(coverage)) do
        if coverage == "" do
          add_error(changeset, :"rnb_row#{index}", "Coverage: Empty strings are not accepted.")
        else
          add_error(changeset, :"rnb_row#{index}", "'#{coverage}' does not belong to available coverages of this plan.")
        end
      else
        valid_coverage = ["mtrnty", "acu", "ip"]
        check_rnb_coverage_level2(changeset, valid_coverage, coverage, index)
      end
    else
      add_error(changeset, :"rnb_row#{index}", "Coverage is required in a room and board.")
    end
  end

  defp check_rnb_coverage_level2(changeset, valid_coverage, coverage, index) do
    if not Enum.member?(valid_coverage, String.downcase(coverage)) do
      if coverage == "" do
        add_error(changeset, :"rnb_row#{index}", "Coverage: Empty strings are not accepted.")
      else
        add_error(changeset, :"rnb_row#{index}", "'#{coverage}' is not a valid coverage for Room and Board.")
      end
    else
      if String.downcase(coverage) == "acu" do
        #benefit_codes = changeset.changes[:benefit]["code"]

        benefit_codes =
          changeset.changes.benefit
          |> benefit_codes_from_params()
        # benefit_codes = benefit_codes_from_params(benefit_param)
        acu_benefit = for b <- benefit_codes do
          record = get_benefit(b)
          _coverages = for bc <- record.benefit_coverages do
            if bc.coverage.name == "ACU" do
              record
            end
          end
        end
        acu_benefit =
          acu_benefit
          |> List.flatten
          |> Enum.uniq
          |> List.delete(nil)
          |> List.first

        acu_type = acu_benefit.acu_type
        acu_coverage = acu_benefit.acu_coverage

        if acu_type == "Executive" and acu_coverage == "Inpatient" do
          nil
        else
          add_error(changeset, :"rnb_row#{index}", "ACU with a type of Executive and a coverage of Inpatient is the only ACU allowed in room and board.")
        end
      else
        nil
      end
    end
  end

  defp check_rnb_type(changeset, rnb, index) do
    if Map.has_key?(rnb, "room_and_board") do
      room_and_board = rnb["room_and_board"]
      valid_rnb = ["alternative", "nomenclature", "peso based"]

      if not Enum.member?(valid_rnb, String.downcase(room_and_board)) do
        if room_and_board == "" do
          add_error(changeset, :"rnb_row#{index}", "Room and Board: Empty strings are not accepted.")
        else
          add_error(changeset, :"rnb_row#{index}", "'#{room_and_board}' is not a valid room and board type.")
        end
      end
    else
      add_error(changeset, :"rnb_row#{index}", "Room and Board type is required in a room and board.")
    end
  end

  defp check_rt(changeset, rnb, index) do
    if String.downcase(rnb["room_and_board"]) == "peso based" do
      if Map.has_key?(rnb, "room_type") do
        add_error(changeset, :"rnb_row#{index}", "Room type can't be filled up with Peso Based room and board.")
      end
    else
      if Map.has_key?(rnb, "room_type") do
        room_type = rnb["room_type"]
        if room_type == "" do
          add_error(changeset, :"rnb_row#{index}", "Room Type: Empty strings are not accepted.")
        else
          room =
            Room
            |> where([r], ilike(r.type, ^room_type))
            |> Repo.one

          if room == nil do
            add_error(changeset, :"rnb_row#{index}", "'#{room_type}' is not a valid room type.")
          end
        end
      else
        add_error(changeset, :"rnb_row#{index}", "Room Type is necessary in an Alternative or a Nomencalture room and board.")
      end
    end
  end

  defp check_rla(changeset, rnb, index) do
    if String.downcase(rnb["room_and_board"]) == "nomenclature" do
      if Map.has_key?(rnb, "room_limit_amount") do
        add_error(changeset, :"rnb_row#{index}", "Room Limit Amount can't be filled up with Nomenclature room and board.")
      end
    else
      if Map.has_key?(rnb, "room_limit_amount") do
        room_limit_amount = rnb["room_limit_amount"]
        if room_limit_amount == "" do
          add_error(changeset, :"rnb_row#{index}", "Room Limit Amount: Empty strings are not accepted.")
        else
          if not validate_decimal(room_limit_amount) do
            add_error(changeset, :"rnb_row#{index}", "'#{room_limit_amount}' is not a valid amount.")
          end
        end
      else
        add_error(changeset, :"rnb_row#{index}", "Room Limit Amount is necessary in an Alternative or a Peso Based room and board.")
      end
    end
  end

  defp check_ru(changeset, rnb, index) do
    if Map.has_key?(rnb, "room_upgrade") do
      room_upgrade = rnb["room_upgrade"]
      if room_upgrade == "" do
        add_error(changeset, :"rnb_row#{index}", "Room Upgrade: Empty strings are not accepted.")
      else
        if not validate_numbers(room_upgrade) do
          add_error(changeset, :"rnb_row#{index}", "'#{room_upgrade}' is not a valid number.")
        end
      end
    end
  end

  defp check_rut(changeset, rnb, index) do
    if Map.has_key?(rnb, "room_upgrade_time") do
      rut = rnb["room_upgrade_time"]
      valid_rut = ["hours", "days"]
      if not Enum.member?(valid_rut, String.downcase(rut)) do
        check_rut_level2(changeset, rut, index)
      end
    end
  end

  defp check_rut_level2(changeset, rut, index) do
    if rut == "" do
      add_error(changeset, :"rnb_row#{index}", "Room Upgrade Time: Empty strings are not accepted.")
    else
      add_error(changeset, :"rnb_row#{index}", "'#{rut}' is not a valid room upgrade time.")
    end
  end

  defp validate_all_number_fields(changeset, changeset_field, field) do
    with true <- validate_a_number_field(changeset_field, field)
    do
      changeset
    else
      {:invalid_number_format, field} ->
        add_error(changeset, field, "Must be a number.")
    end
  end

  defp validate_a_number_field(numbers, field_name) do
    valid_format = validate_numbers(numbers)
    if valid_format do
      true
    else
      {:invalid_number_format, field_name}
    end
  end

  def validate_number_field(numbers) do
    for number <- numbers do
      valid_format = validate_numbers(number)
      if valid_format do
        true
      else
        false
      end
    end
  end

  def validate_numbers(string) do
    Regex.match?(~r/^[0-9]*$/, string)
  end

  defp validate_all_decimal_fields(changeset, changeset_field, field) do
    with true <- validate_a_decimal_field(changeset_field, field)
    do
      changeset
    else
      {:invalid_number_format, field} ->
        add_error(changeset, field, "Must be a valid amount(No commas).")
    end
  end

  defp validate_a_decimal_field(numbers, field_name) do
    valid_format = validate_decimal(numbers)
    if valid_format do
      true
    else
      {:invalid_number_format, field_name}
    end
  end

  def validate_decimal_field(numbers) do
    for number <- numbers do
      valid_format = validate_decimal(number)
      if valid_format do
        true
      else
        false
      end
    end
  end

  defp validate_decimal(string) do
    Regex.match?(~r/^(?!\.?$)[1-9]\d{0,5}(\.\d{0,2})?$/, string)
  end

  defp insert_product(product_params \\ %{}, user) do
    if is_nil(product_params.changes[:code]) do
      maxicare = Repo.get_by(Payor, name: "Maxicare")
      product_params =
        product_params.changes
        |> Map.merge(%{
          step: "8",
          created_by_id: user.id,
          updated_by_id: user.id,
          payor_id: maxicare.id
        })

      %Product{}
      |> Product.changeset_general(product_params)
      |> Repo.insert()
    else
      maxicare = Repo.get_by(Payor, name: "Maxicare")
      product_params =
        product_params.changes
        |> Map.merge(%{
          step: "8",
          created_by_id: user.id,
          updated_by_id: user.id,
          payor_id: maxicare.id
        })

        product_params =
          product_params
          |> Map.put(:member_type, start_case(product_params.member_type))

      %Product{}
      |> Product.changeset_api(product_params)
      |> Repo.insert()
    end
  end

  defp start_case(member_type) do
    member_type
    |> Enum.map(fn(x) -> String.capitalize(x) end)
    |> Enum.sort(&(&1 >= &2))
  end

  defp insert_exclusion(changeset, product) do
    if is_nil(changeset.changes[:exclusion]) do
      # changeset <- unused
      {:ok}
    else
      _exclusion_ids = for exclusion <- changeset.changes.exclusion["code"] do
        exclusion_id = get_exclusion_by_code(exclusion)
        result = MainProductContext.genex_and_pre_existing_checker(product.id, exclusion_id)
        if result == true do
          params = %{product_id: product.id, exclusion_id: exclusion_id}
          changeset_genex = ProductExclusion.changeset(% ProductExclusion{}, params)
          Repo.insert!(changeset_genex)
        end
      end
      {:ok}
    end
  end

  def insert_benefit(changeset, product, user) do
    benefit_codes =
      changeset.changes.benefit
      |> benefit_codes_from_params_without_limit()

    benefit_ids = Enum.map(benefit_codes, &(get_benefit_id_by_code(&1)))
    changeset = Map.put(changeset, :changes, Map.put(changeset.changes, :benefit_ids, benefit_ids))
    MainProductContext.set_product_benefits(product, changeset.changes.benefit_ids, user.id)
  end

  def insert_benefit_with_limits(changeset, product) do
    benefits =
      changeset.changes.benefit
      |> filter_benefits_with_limit()
    benefits = Enum.map(benefits, &({&1, get_benefit_id_by_code(&1["code"])}))
    set_product_benefits_with_limit(product, benefits)
  end

  def set_product_benefits_with_limit(product, benefits) do
    case product.product_category do
      "Regular Plan" ->
        benefit_id_list = Enum.map(benefits, fn({benefit, id}) -> id end)
        benefit_id_list
        |> Enum.into([], fn(x) -> BenefitContext.get_benefit(x).benefit_coverages
        |> Enum.map(fn(y) -> y.coverage.description end)
        end)
        |> List.flatten()
        |> Enum.filter(&(&1 == "ACU"))
        |> Enum.count()
        |> result_count(product.id, benefits, "Only one ACU benefit can be added.", "ACU")

      "PEME Plan" ->
        benefit_id_list = Enum.map(benefits, fn({benefit, id}) -> id end)
        benefit_id_list
        |> Enum.into([], fn(x) -> BenefitContext.get_benefit(x).benefit_coverages
        |> Enum.map(fn(y) -> y.coverage.description end)
        end)
        |> List.flatten()
        |> Enum.filter(&(&1 == "PEME"))
        |> Enum.count()
        |> result_count(product.id, benefits, "Only one PEME benefit can be added.", "PEME")

      "Dental Plan" ->
        benefit_id_list = Enum.map(benefits, fn({benefit, id}) -> id end)
        benefit_id_list
        |> Enum.into([], fn(x) -> BenefitContext.get_benefit(x).benefit_coverages
        |> Enum.map(fn(y) -> y.coverage.description end)
        end)
        |> List.flatten()
        |> Enum.filter(&(&1 == "Dental"))
        |> Enum.count()
        |> result_count(product.id, benefits, "", "Dental")
    end
    rescue
      _ ->
        {:error, "Error in Plan Category"}
  end

  defp result_count(count, id, benefits, message, category) when category == "Dental", do: insert_product_benefits(id, benefits)
  defp result_count(count, id, benefits, message, category) when category != "Dental", do: if count > 1, do: {:error, message}, else: insert_product_benefits(id, benefits)

  defp insert_product_benefits(product_id, benefits) do
    for {benefit, benefit_id} <- benefits do
      result = MainProductContext.benefit_checker(product_id, benefit_id)
      if result == false do
        params = %{benefit_id: benefit_id, product_id: product_id}
        changeset = ProductBenefit.changeset(%ProductBenefit{}, params)

        product_benefit =
          changeset
          |> Repo.insert!()
          |> Repo.preload(benefit: :benefit_limits)

          product = MainProductContext.get_product!(product_id)
          MainProductContext.set_product_coverage(product)

          for benefit_limit <- benefit["coverage"] do
            params = setup_bl_params(benefit_limit, product_benefit.id)

            changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{}, params)
            Repo.insert!(changeset)
          end
      end
    end
    {:ok}
  end

  defp insert_acu_session(params, product_benefit_id) do
    params = %{
      coverages: "ACU",
      limit_type: "Sessions",
      limit_percentage: nil,
      limit_amount: nil,
      limit_session: 1,
      limit_classification: params["limit_classification"],
      product_benefit_id: product_benefit_id
    }
    changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{}, params)
    Repo.insert!(changeset)
  end

  defp setup_bl_params(%{"code" => ["ACU"]} = params, product_benefit_id) do
    insert_acu_session(params, product_benefit_id)
    %{
      coverages: Enum.join(params["code"], ", "),
      limit_type: "Peso",
      limit_percentage: nil,
      limit_amount: params["limit_value"],
      limit_session: nil,
      limit_classification: params["limit_classification"],
      product_benefit_id: product_benefit_id
    }
  end

  defp setup_bl_params(params, product_benefit_id) do
    {percentage, amount, session, tooth, quadrant} = setup_bl_amounts(params)
    %{
      coverages: Enum.join(params["code"], ", "),
      limit_type: params["limit_type"],
      limit_percentage: percentage,
      limit_amount: amount,
      limit_session: session,
      limit_tooth: tooth,
      limit_quadrant: quadrant,
      limit_classification: params["limit_classification"],
      limit_area: params["limit_area"],
      limit_area_type: params["limit_area_type"],
      product_benefit_id: product_benefit_id
    }
  end

  defp setup_bl_amounts(%{"limit_type" => "Plan Limit Percentage"} = params), do: {params["limit_value"], nil, nil, nil, nil}
  defp setup_bl_amounts(%{"limit_type" => "Peso"} = params), do: {nil, params["limit_value"], nil, nil, nil}
  defp setup_bl_amounts(%{"limit_type" => "Sessions"} = params), do: {nil, nil, params["limit_value"], nil, nil}
  defp setup_bl_amounts(%{"limit_type" => "Tooth"} = params), do: {nil, nil, nil, params["limit_value"], nil}
  defp setup_bl_amounts(%{"limit_type" => "Quadrant"} = params), do: {nil, nil, nil, nil, params["limit_value"]}
  defp setup_bl_amounts(params), do: {nil, nil, nil, nil, nil}

  ## for exclusion baseg
  defp insert_coverage(changeset, product) do
    coverage_ids = for coverage <- changeset.changes.coverage do
       get_coverage_by_name(coverage)
    end
    MainProductContext.set_coverage(product.id, coverage_ids)
  end

  def insert_product_coverage_facility(changeset, product) do
    _product_coverages = for facility <- changeset.changes.facility do
      coverage_id = get_coverage_by_name(facility["coverage"])
      product_coverage_id = get_product_coverage_id(coverage_id, product.id)
      # updating product_coverage.type
      product_coverage = get_product_coverage(product_coverage_id)

      params = %{
        type: facility["type"] |> convert_type(),
        coverage_id: coverage_id,
        product_id: product.id
      }

      if not is_nil(facility["code"]) do
        facility_ids = for f_code <- facility["code"] do
          _f_id = get_facility_by_code(f_code)
        end
        location_group = facility["location_group"]
        MainProductContext.set_product_facility(product_coverage_id, facility_ids)
      end

      MainProductContext.add_facility_by_location_group(location_group, product_coverage_id)
      MainProductContext.set_product_coverage_type(product_coverage, params)
    end

    {:ok}
  end

  def convert_type(type), do: if String.downcase(type) == "all", do: "exception", else: String.downcase(type)

  defp insert_limit_threshold(changeset, product) do
    if is_nil(changeset.changes[:limit_threshold]) do
      {:ok}
    else
      for lt <- changeset.changes.limit_threshold do
        coverage_id = get_coverage_by_name(lt["coverage"])
        product_coverage_id = get_product_coverage_id(coverage_id, product.id)
        product_coverage = get_product_coverage(product_coverage_id)

        params = %{
          product_coverage_id: product_coverage.id,
          limit_threshold: lt["limit_threshold"]
        }

        pclt =
          ProductCoverageLimitThreshold
          |> where([pclt], pclt.product_coverage_id == ^product_coverage.id)
          |> Repo.one

        pclt_record =
          pclt
          |> ProductCoverageLimitThreshold.changeset(params)
          |> Repo.update!

        if not is_nil(lt["limit_threshold_facilities"]) do
          for ltr <- lt["limit_threshold_facilities"] do
            MainProductContext.insert_pcltf(
              pclt_record.id,
              get_facility_by_code(ltr["facility_code"]),
              ltr["limit_threshold"]
            )
          end
        end
      end
      {:ok}
    end
  end

  defp condition_params(changeset, product) do
    changeset =
      changeset.changes
      |> Map.put_new(:adnb, "")
      |> Map.put_new(:opmnnb, "")
      |> Map.put_new(:opmnb, "")
      |> Map.put_new(:adnnb, "")
      |> Map.put_new(:nem_principal, "")
      |> Map.put_new(:nem_dependent, "")
      |> Map.put_new(:principal_min_age, "")
      |> Map.put_new(:principal_min_type, "")
      |> Map.put_new(:principal_max_age, "")
      |> Map.put_new(:principal_max_type, "")
      |> Map.put_new(:medina_processing_limit, "")
      |> Map.put_new(:sop_principal, "")
      |> Map.put_new(:sop_dependent, "")

    params = %{
      nem_principal: changeset.nem_principal,
      nem_dependent: changeset.nem_dependent,
      principal_min_age: changeset.principal_min_age,
      principal_min_type: changeset.principal_min_type,
      principal_max_age: changeset.principal_max_age,
      principal_max_type: changeset.principal_max_type,
      adult_dependent_min_age: changeset.adult_dependent_min_age,
      adult_dependent_min_type: changeset.adult_dependent_min_type,
      adult_dependent_max_age: changeset.adult_dependent_max_age,
      adult_dependent_max_type: changeset.adult_dependent_max_type,
      minor_dependent_min_age: changeset.minor_dependent_min_age,
      minor_dependent_min_type: changeset.minor_dependent_min_type,
      minor_dependent_max_age: changeset.minor_dependent_max_age,
      minor_dependent_max_type: changeset.minor_dependent_max_type,
      overage_dependent_min_age: changeset.overage_dependent_min_age,
      overage_dependent_min_type: changeset.overage_dependent_min_type,
      overage_dependent_max_age: changeset.overage_dependent_max_age,
      overage_dependent_max_type: changeset.overage_dependent_max_type,
      adnb: changeset.adnb,
      adnnb: changeset.adnnb,
      opmnb: changeset.opmnb,
      opmnnb: changeset.opmnnb,
      no_outright_denial: convert_no_outright_denial(changeset.no_outright_denial),
      no_days_valid: changeset.no_of_days_valid,
      is_medina: convert_is_medina(changeset.is_medina),
      loa_facilitated: convert_loa_facilitated(changeset.loa_facilitated),
      smp_limit: changeset.medina_processing_limit,
      hierarchy_waiver: changeset.hierarchy_waiver,
      sop_principal: changeset.sop_principal,
      sop_dependent: changeset.sop_dependent
    }

    MainProductContext.update_product_condition(product, params)
  end

  defp convert_is_medina(is_medina) do
    case is_medina do
      "Yes" ->
        true
      "No" ->
        false
    end
  end

  defp convert_no_outright_denial(nod) do
    case nod do
      "True" ->
        true
      "False" ->
        false
    end
  end

  defp convert_loa_facilitated(lf) do
    case lf do
      "True" ->
        true
      "False" ->
        false
    end
  end

  defp insert_condition(changeset, product) do
    condition_params(changeset, product)

    ## for funding arrangement
    for funding_arrangement <- changeset.changes.funding_arrangement do
      coverage_id = get_coverage_by_name(funding_arrangement["coverage"])
      product_coverage_id = get_product_coverage_id(coverage_id, product.id)

      product_coverage = get_product_coverage(product_coverage_id)

      params = %{funding_arrangement: funding_arrangement["type"]}
      changeset = ProductCoverage.changeset_funding(product_coverage, params)
      Repo.update(changeset)
    end

    ## for Room and Board
    if is_nil(changeset.changes[:rnb]) do
      changeset
    else
      for rnb <- changeset.changes.rnb do
        coverage_id = get_coverage_by_name(rnb["coverage"])
        product_coverage_id = get_product_coverage_id(coverage_id, product.id)
        room_id = if is_nil(rnb["room_type"]) do
          nil
        else
          get_room_by_type(rnb["room_type"])
        end
        # updating product_coverage.type
        product_coverage = get_product_coverage(product_coverage_id)

        pcrnb_id = product_coverage.product_coverage_room_and_board.id
        product_coverage_rnb = MainProductContext.get_pc_rnb(pcrnb_id)
        params = case String.downcase(rnb["room_and_board"]) do
          "alternative" ->
            %{
              "room_and_board" => rnb["room_and_board"],
              "room_limit_amount" => rnb["room_limit_amount"],
              "room_upgrade" => rnb["room_upgrade"],
              "room_type" => room_id,
              "room_upgrade_time" => rnb["room_upgrade_time"]
            }
          "nomenclature" ->
            %{
              "room_and_board" => rnb["room_and_board"],
              "room_limit_amount" => nil,
              "room_upgrade" => rnb["room_upgrade"],
              "room_type" => room_id,
              "room_upgrade_time" => rnb["room_upgrade_time"]
            }
          "peso based" ->
            %{
              "room_and_board" => rnb["room_and_board"],
              "room_limit_amount" => rnb["room_limit_amount"],
              "room_upgrade" => rnb["room_upgrade"],
              "room_type" => nil,
              "room_upgrade_time" => rnb["room_upgrade_time"]
            }
        end
        product_coverage_rnb
        |> ProductCoverageRoomAndBoard.changeset_update(params)
        |> Repo.update()
      end
    end
    {:ok}
  end

  defp insert_product_coverage_risk_share(changeset, product) do
    if is_nil(changeset.changes[:risk_share]) do
      # changeset <- unused
      {:ok}
    else
      for risk_share <- changeset.changes.risk_share do

        coverage_id = get_coverage_by_name(risk_share["coverage"])
        product_coverage_id = get_product_coverage_id(coverage_id, product.id)

        product_coverage = get_product_coverage(product_coverage_id)
        pc_rs_id = product_coverage.product_coverage_risk_share.id
        pcrs_struct = MainProductContext.get_product_risk_share(pc_rs_id)

        ## insertion for product_coverage_risk_share
        params = %{
          "af_type" => risk_share["af_type"],
          "af_value" => risk_share["af_value"],
          "af_covered_percentage" => risk_share["af_covered"],
          "naf_reimbursable" => risk_share["naf_reimbursable"],
          "naf_type" => risk_share["naf_type"],
          "naf_value" => risk_share["naf_value"],
          "naf_covered_percentage" => risk_share["naf_covered"]
        }
        MainProductContext.update_product_risk_share(pcrs_struct, params)

        ## insertion for product_coverage_risk_share_facilities
        if risk_share["exempted_facilities"] != nil do
          _facility_ids = for facility <- risk_share["exempted_facilities"] do
            facility_id = get_facility_by_code(facility["facility_code"])
            params = %{
              "covered" => facility["covered"],
              "facility_id" => facility_id,
              "product_coverage_risk_share_id" => pcrs_struct.id,
              "type" => facility["type"],
              "value" => facility["value"],
              "product_risk_share_facility_id" => "",
              "product_risk_share_id" => pcrs_struct.id
            }
            {:ok, pcrsf} = MainProductContext.set_product_risk_share_facility(params)

            ## insertion for product_coverage_risk_share_facility_procedures
            if facility["exempted_procedures"] != nil do
              for procedure <- facility["exempted_procedures"] do
                fpp_struct = get_fpp_by_code(procedure["facility_cpt_code"])
                params = %{
                  "covered" => procedure["covered"],
                  "pcrsfpp" => "",
                  "procedure_id" => fpp_struct.id,
                  "product_risk_share_facility_id" => pcrsf.id,
                  "type" => procedure["type"],
                  "value" => procedure["value"]
                }
                MainProductContext.set_product_risk_share_facility_procedure(params)
              end
            end
          end
        end

      end
      {:ok}
    end
  end

  def get_benefit_id_by_code(code) do
    Benefit
    # |> where([b], ilike(b.code, ^code))
    |> where([b], b.code == ^code)
    |> select([b], b.id)
    |> Repo.one()
  end

  def get_facility_by_code(code) do
    Facility
    |> where([f], f.code == ^code)
    |> select([f], f.id)
    |> Repo.one()
  end

  def get_exclusion_by_code(code) do
    Exclusion
    |> where([e], ilike(e.code, ^code))
    |> select([e], e.id)
    |> Repo.one()
  end

  def get_coverage_by_name(code) do
    Coverage
    |> where([c], c.code == ^code)
    |> select([c], c.id)
    |> Repo.one()
  end

  def get_product_coverage_id(coverage_id, product_id) do
    ProductCoverage
    |> where([pc], pc.coverage_id == ^coverage_id and pc.product_id == ^product_id)
    |> select([pc], pc.id)
    |> Repo.one()
  end

  def get_product_coverage(nil), do: nil
  def get_product_coverage(pc_id) do
    ProductCoverage
    |> Repo.get(pc_id)
    |> Repo.preload([:product_coverage_room_and_board,
                     :product_coverage_risk_share,
                     :product_coverage_dental_risk_share
    ])
  end

  def get_room_by_type(type) do
    Room
    |> where([r], ilike(r.type, ^type))
    |> select([r], r.id)
    |> Repo.one()
  end

  def get_fpp_by_code(fpp_code) do
    FacilityPayorProcedure
    |> where([fpp], ilike(fpp.code, ^fpp_code))
    |> Repo.one()
  end

  def merge_changeset_errors([head | tails], changeset) do
    # Merges errors in changeset.
    prev_changeset = changeset
    new_changeset = head
    merge_changeset_errors(tails, merge(prev_changeset, new_changeset))
  end

  def merge_changeset_errors([], changeset), do: changeset
    # Merges errors in changeset.

  # End of generic functions.

  # Change Member Product

  def validate_change_member_product(user, data) do
    if is_nil(user) do
      {:invalid_credentials}
    else
      validate_change_member_product_level2(user, data)
    end
  end

  defp validate_change_member_product_level2(user, %{"change_of_product" => params}) do
    results =
      for data <- params do
        params = %{
          coped: data["change_of_product_effective_date"],
          member_id: data["member_id"],
          new_product_code: data["new_product_code"],
          old_product_code: data["old_product_code"],
          reason: data["reason"],
          error: []
        }

        general_types = %{
          coped: :string,
          member_id: :string,
          new_product_code: :string,
          old_product_code: :string,
          reason: :string,
          error: {:array, :string}
        }

        changeset =
          {%{}, general_types}
          |> cast(params, Map.keys(general_types))
          |> validate_if_required(:coped, "Change of Product Effective Date")
          |> validate_if_required(:member_id, "Member ID")
          |> validate_if_required(:new_product_code, "New Product Code")
          |> validate_if_required(:old_product_code, "Old Product Code")
          |> validate_if_required(:reason, "Reason")

        errors =
          changeset.changes[:error]
          |> List.flatten

        if Enum.empty?(errors) do
          validate_change_member_product_level3(user, changeset)
        else
          {:error, changeset}
        end
      end

    check_errors =
      results
      |> Enum.filter(&(&1 != {:ok}))

    if Enum.empty?(check_errors) do
      result =
        for data <- params do
          coped_splitted =
            data["change_of_product_effective_date"]
            |> String.split("-")

          {:ok, coped} = Date.new(
            cti(Enum.at(coped_splitted, 0)),
            cti(Enum.at(coped_splitted, 1)),
            cti(Enum.at(coped_splitted, 2))
          )

          cop_log = MainProductContext.insert_change_of_product_log(
            %{
              change_of_product_effective_date: coped,
              member_id: data["member_id"],
              reason: data["reason"],
              created_by_id: user.id
            }
          )
          member = MemberContext.get_member!(data["member_id"])

          old_product_code = if data["old_product_code"] == "ALL" do
            member.products
            |> Enum.map(
              &(
                if &1.is_archived != true, do: &1.account_product.product.code
              )
            )
            |> Enum.join(";")
          else
            data["old_product_code"]
          end

          MainProductContext.insert_changed_member_product(
            %{
              cop_log_id: cop_log.id,
              new_product_code: data["new_product_code"],
              old_product_code: old_product_code
            }
          )
          MemberContext.delete_cop_member_products(
            old_product_code,
            member
          )
          MemberContext.reassign_tier_cop_mp(
            member.id
          )
          MemberContext.update_cop_member_products(
            data["new_product_code"],
            member
          )

          cop_log
          |> Repo.preload([
            :members,
            changed_member_products: :product
          ])
        end
      {:ok, result}
    else
      parent_changeset =
        {%{}, %{change_of_product: :string}}
        |> cast(%{change_of_product: ""}, Map.keys(%{change_of_product: :string}))

      error_changeset = for {{result, changeset}, index} <- Enum.with_index(check_errors, 1) do
        errors =
          changeset.changes[:error]
          |> List.flatten()

        row = :"change_of_product_row_#{index}"
        for error <- errors do
          add_error(changeset, row, error)
        end
      end
      |> List.flatten
      |> merge_changeset_errors(parent_changeset)

      {:error, error_changeset}
    end
  end

  defp validate_change_member_product_level3(user, changeset) do
    changeset =
      changeset
      |> validate_member_id

    errors =
      changeset.changes[:error]
      |> List.flatten

    if Enum.empty?(errors) do
      validate_change_member_product_level4(user, changeset)
    else
      {:error, changeset}
    end
  end

  defp validate_change_member_product_level4(user, changeset) do
    changeset =
      changeset
      |> validate_reason
      |> validate_coped
      |> validate_new_product
      |> validate_old_product

    errors =
      changeset.changes[:error]
      |> List.flatten

    if Enum.empty?(errors) do
      {:ok}
    else
      {:error, changeset}
    end
  end

  defp validate_if_required(changeset, field, field_name) do
    value = changeset.changes[field]
    if value == "" or is_nil(value) do
      error_val = changeset.changes[:error] ++ ["Please enter #{field_name}"]
      put_change(changeset, :error, error_val)
    else
      changeset
    end
  end

  defp validate_member_id(changeset) do
    member_id = changeset.changes[:member_id]

    case UtilityContext.valid_uuid?(member_id) do
      {true, id} ->
        result = Repo.get(Member, member_id)
        if not is_nil(result) do
          validate_member_id_level2(changeset)
        else
          error_val = changeset.changes[:error] ++ ["Member does not exist"]
          put_change(changeset, :error, error_val)
        end
      {:invalid_id} ->
        error_val = changeset.changes[:error] ++ ["Invalid member id"]
        put_change(changeset, :error, error_val)
    end
  end

  defp validate_member_id_level2(changeset) do
    member =
      Member
      |> Repo.get(changeset.changes[:member_id])

    cond do
      is_nil(member.status) ->
        error_val = changeset.changes[:error] ++ ["Invalid member status"]
        put_change(changeset, :error, error_val)
      String.upcase(member.status) == "CANCELLED" ->
        error_val = changeset.changes[:error] ++ ["The member you entered is cancelled"]
        put_change(changeset, :error, error_val)
      String.upcase(member.status) == "SUSPENDED" ->
        error_val = changeset.changes[:error] ++ ["The member you entered is suspended"]
        put_change(changeset, :error, error_val)
      true ->
        changeset
    end
  end

  defp validate_reason(changeset) do
    reason_count =
      changeset.changes[:reason]
      |> String.split("")
      |> Enum.count

    if reason_count > 255 do
      error_val = changeset.changes[:error] ++ ["Reason must only be 255 characters"]
      put_change(changeset, :error, error_val)
    else
      changeset
    end
  end

  defp validate_date(date) do
    [yyyy, mm, dd] = String.split(date, "-")
    if String.length(dd) == 1, do: dd = "0#{dd}"
    if String.length(mm) == 1, do: mm = "0#{mm}"
    if String.length(yyyy) == 2, do: yyyy = "20#{yyyy}"
    date = Ecto.Date.cast!("#{yyyy}-#{mm}-#{dd}")
    {:true, date}
  rescue
    MatchError ->
      {:invalid_date}
    ArgumentError ->
      {:invalid_date}
    Ecto.CastError ->
      {:invalid_date}
    FunctionClauseError ->
      {:invalid_date}
    _ ->
      {:invalid_date}
  end

  defp validate_coped(changeset) do
    coped = changeset.changes[:coped]

    with {:true, date} <- validate_date(coped)
    do

      validate_coped_level2(changeset)
    else
      _ ->
        error_val = changeset.changes[:error] ++ ["Invalid effective date, date must be in yyyy-mm-dd format"]
        put_change(changeset, :error, error_val)
    end
  end

  defp validate_coped_level2(changeset) do
    member =
      Member
      |> Repo.get(changeset.changes[:member_id])

    {:true, coped_date} =
      changeset.changes[:coped]
      |> validate_date

    member =
      Member
      |> Repo.get(changeset.changes[:member_id])

    with true <- validate_member_date(
                  coped_date,
                  member.effectivity_date,
                  member.expiry_date
                ),
         true <- validate_member_date(
                  coped_date,
                  member.cancel_date
                ),
         true <- validate_member_date(
                  coped_date,
                  member.suspend_date
                )
    do
      validate_coped_level3(changeset)
    else
      {:invalid_member_range} ->
        error_val = changeset.changes[:error] ++ ["Date must be within the coverage period of the member"]
        put_change(changeset, :error, error_val)
      {:invalid_cancel_suspend} ->
        error_val = changeset.changes[:error] ++ ["Date must not be greater than future cancellation and/or suspension date of the member"]
        put_change(changeset, :error, error_val)
    end
  end

  def validate_member_date(
    coped_date,
    effectivity_date,
    expiry_date
  ) do
    result_effectivity =
      case Ecto.Date.compare(coped_date, effectivity_date) do
        :lt ->
          false
        _ ->
          true
      end

    result_expiry =
      case Ecto.Date.compare(coped_date, expiry_date) do
        :gt ->
          false
        _ ->
          true
      end

    result = [result_effectivity, result_expiry]

    if Enum.member?(result, false) do
      {:invalid_member_range}
    else
      true
    end
  end

  def validate_member_date(
    coped_date,
    date
  ) do
    if not is_nil(date) do
      case Ecto.Date.compare(coped_date, date) do
        :gt ->
          {:invalid_cancel_suspend}
        _ ->
          true
      end
    else
      true
    end
  end

  defp validate_coped_level3(changeset) do
    member =
      Member
      |> Repo.get(changeset.changes[:member_id])

    coped =
      changeset.changes[:coped]
      |> String.split("-")

    today = Date.utc_today()

    with true <- cti(Enum.at(coped, 1)) >= today.month,
         true <- validate_cop_day(coped, today.day, today.month),
         true <- cti(Enum.at(coped, 0)) >= today.year
    do
      changeset
    else
      _ ->
        error_val = changeset.changes[:error] ++ ["Date must be current date or future dated"]
        put_change(changeset, :error, error_val)
    end
  end

  defp validate_cop_day(coped, current_day, current_month) do
    month = cti(Enum.at(coped, 1))
    day = cti(Enum.at(coped, 2))

    if month == current_month do
      if day >= current_day do
        true
      else
        false
      end
    else
      true
    end
  end

  defp cti(str), do: String.to_integer(str)

  defp validate_old_product(changeset) do
    member = MemberContext.get_member!(changeset.changes[:member_id])

    if changeset.changes[:old_product_code] == "ALL" do
      member_products =
        member.products
        |> Enum.map(
          &(
            if &1.is_archived != true, do: &1.account_product.product.code
          )
        )
        |> Enum.join(";")

      put_change(changeset, :old_product_code, member_products)
    else
      old_product_code =
        changeset.changes[:old_product_code]
        |> String.split(";")
        |> Enum.map(&(String.upcase(&1)))

      existing_product = for mp <- member.products do
        if mp.is_archived != true do
          mp.account_product.product.code
          |> String.upcase
        end
      end
      |> Enum.filter(&(not is_nil(&1)))

      result = old_product_code -- existing_product

      if Enum.empty?(result) do
        changeset
      else
        errors =
          for error <- result do
            if error == "ALL" do
              "'ALL' cannot not be used with other plan code."
            else
              "This #{error} is not within the member"
            end
          end
          |> Enum.join(",")

        error_val = changeset.changes[:error] ++ [errors]
        put_change(changeset, :error, error_val)
      end
    end
  end

  defp validate_new_product(changeset) do
    member = MemberContext.get_member!(changeset.changes[:member_id])
    new_product_code =
      changeset.changes[:new_product_code]
      |> String.split(";")
      |> Enum.map(&(String.upcase(&1)))

    old_product_code =
      changeset.changes[:old_product_code]
      |> String.split(";")
      |> Enum.map(&(String.upcase(&1)))

    account =
      member.account_group.id
      |> AccountContext.get_latest_account
      |> Repo.preload([
        account_products: [
          :product
        ]
      ])

    products = for ap <- account.account_products do
      ap.product.code
      |> String.upcase
    end

    result = new_product_code -- products

    if Enum.empty?(result) do
      validate_new_product_level2(changeset)
    else
      errors =
        for error <- result do
          "This #{error} is not within the account"
        end
        |> Enum.join(",")

      error_val = changeset.changes[:error] ++ [errors]
      put_change(changeset, :error, error_val)
    end
  end

  defp validate_new_product_level2(changeset) do
    member = MemberContext.get_member!(changeset.changes[:member_id])
    new_product_code =
      changeset.changes[:new_product_code]
      |> String.split(";")
      |> Enum.map(&(String.upcase(&1)))

    old_product_code =
      member.products
      |> Enum.map(
        &(
          if &1.is_archived != true, do: &1.account_product.product.code
        )
      )
      |> Enum.join(";")
      |> String.split(";")
      |> Enum.map(&(String.upcase(&1)))

    new_product_count = Enum.count(new_product_code)
    duplicate_result = new_product_code -- old_product_code

    if Enum.count(duplicate_result) == new_product_count do
      validate_new_product_level3(changeset)
    else
      errors =
        for error <- new_product_code do
          if Enum.member?(old_product_code, error) do
            "#{error} already exists in the member"
          end
        end
        |> Enum.filter(&(not is_nil(&1)))
        |> Enum.join(",")

      error_val = changeset.changes[:error] ++ [errors]
      put_change(changeset, :error, error_val)
    end
  end

  def age(%Ecto.Date{day: d, month: m, year: y}, as_of \\ :now) do
    do_age({y, m, d}, as_of)
  end

  def do_age(birthday, :now) do
    {today, _time} = :calendar.now_to_datetime(:erlang.now)
    calc_diff(birthday, today)
  end

  def do_age(birthday, date), do: calc_diff(birthday, date)

  def calc_diff({y1, m1, d1}, {y2, m2, d2}) when m2 > m1 or (m2 == m1 and d2 >= d1) do
    y2 - y1
  end

  def calc_diff({y1, _, _}, {y2, _, _}), do: (y2 - y1) - 1

  defp validate_new_product_level3(changeset) do
    member = MemberContext.get_member!(changeset.changes[:member_id])
    new_product_code =
      changeset.changes[:new_product_code]
      |> String.split(";")
      |> Enum.map(&(String.upcase(&1)))

    account =
      member.account_group.id
      |> AccountContext.get_latest_account
      |> Repo.preload([
        account_products: [
          :product
        ]
      ])

    member = MemberContext.get_member!(changeset.changes[:member_id])

    member_age =
      member.birthdate
      |> age

    products = for ap <- account.account_products do
      if Enum.member?(new_product_code, String.upcase(ap.product.code)) do
        ap.product
      end
    end
    |> Enum.filter(&(not is_nil(&1)))

    result = for p <- products do
      age_result =
        case member.type do
          "Principal" ->
            check_principal_guardian_age(member_age, p)
          "Dependent" ->
            check_dependent_age(member_age, p)
          "Guardian" ->
            check_principal_guardian_age(member_age, p)
        end

      if age_result do
        nil
      else
        "Member's age is not eligible for #{p.code}"
      end
    end
    |> Enum.filter(&(not is_nil(&1)))

    if Enum.empty?(result) do
      changeset
      |> validate_new_product_level4()
    else
      result
      |> Enum.join(",")

      error_val = changeset.changes[:error] ++ [result]
      put_change(changeset, :error, error_val)
    end
  end

  defp check_principal_guardian_age(member_age, p) do
    min_age =
      p.principal_min_age
      |> convert_age_to_year(p.principal_min_type)

    max_age =
      p.principal_max_age
      |> convert_age_to_year(p.principal_max_type)

    check_mp_age_eligibility(member_age, min_age, max_age)
  end

  defp check_dependent_age(member_age, p) do
    adult_min_age =
      p.adult_dependent_min_age
      |> convert_age_to_year(p.adult_dependent_min_type)

    adult_max_age =
      p.adult_dependent_max_age
      |> convert_age_to_year(p.adult_dependent_max_type)

    minor_min_age =
      p.minor_dependent_min_age
      |> convert_age_to_year(p.minor_dependent_min_type)

    minor_max_age =
      p.minor_dependent_max_age
      |> convert_age_to_year(p.minor_dependent_max_type)

    overage_min_age =
      p.overage_dependent_min_age
      |> convert_age_to_year(p.overage_dependent_min_type)

    overage_max_age =
      p.overage_dependent_max_age
      |> convert_age_to_year(p.overage_dependent_max_type)

    adult_result = check_mp_age_eligibility(member_age, adult_min_age, adult_max_age)
    minor_result = check_mp_age_eligibility(member_age, minor_min_age, minor_max_age)
    overage_result = check_mp_age_eligibility(member_age, overage_min_age, overage_max_age)

    overall_result = [
      adult_result,
      minor_result,
      overage_result
    ]

    if Enum.member?(overall_result, true) do
      true
    else
      false
    end
  end

  defp validate_new_product_level4(changeset) do
    new_product_code =
      changeset.changes[:new_product_code]
      |> String.split(";")
      |> Enum.map(&(String.upcase(&1)))

    result = for pc <- new_product_code do
      product =
        Product
        |> where([p], ilike(p.code, ^pc))
        |> Repo.one()
        |> Repo.preload([
          product_coverages: :coverage
        ])

      coverage_result =
        for pc <- product.product_coverages do
          if pc.coverage.name == "ACU" do
            "ACU"
          end
        end

      if Enum.member?(coverage_result, "ACU") do
        {:has_acu}
      else
        nil
      end
    end
    |> Enum.filter(&(&1 == {:has_acu}))
    |> Enum.count

    if result > 1 do
      error_val = changeset.changes[:error] ++ ["You are only allowed to enter 1 plan with ACU Benefit"]
      put_change(changeset, :error, error_val)
    else
      changeset
    end
  end

  defp convert_age_to_year(age, type) do
    case String.upcase(type) do
      "YEARS" ->
        age
      "MONTHS" ->
        age / 12
      "WEEKS" ->
        age / 52
      "DAYS" ->
        age / 365
    end
  end

  defp check_mp_age_eligibility(
    age,
    age_from,
    age_to
  ) do
    if age >= age_from and age <= age_to do
      true
    else
      false
    end
  end

  # End of Change Member Product

  def get_facility_by_facility_group(facility_group_id) do
    FacilityLocationGroup
    |> Repo.get(facility_group_id)
    |> Repo.all()
    |> Repo.preload([:facility, :location_group])
  end

end
