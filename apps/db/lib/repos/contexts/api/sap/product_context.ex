defmodule Innerpeace.Db.Base.Api.Sap.ProductContext do
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
    Schemas.BenefitProcedure,
    Schemas.PayorProcedure,
    Schemas.Dropdown
  }

  alias Innerpeace.Db.Base.ProductContext, as: MainProductContext1
  alias Innerpeace.Db.Base.Api.ProductContext, as: ApiProductContext
  alias Innerpeace.Db.Base.{
    AccountContext,
    FacilityContext,
    LocationGroupContext,
    MemberContext,
    BenefitContext,
    Api.UtilityContext
  }

  import Ecto.Query

  #DENTAL PLAN API FUNCTIONS

  def validate_insert_dental(user, params) when is_nil(user), do: {:invalid_credentials}
  def validate_insert_dental(user, params) do
    if is_nil(params["product_base"]) || !Map.has_key?(params, "product_base") do
      {:product_base_invalid}
    else
      product_base = String.downcase(params["product_base"])
      changeset =
        {%{}, %{product_base: :string}}
        |> cast(
          %{"product_base" => product_base},
          Map.keys(%{product_base: :string})
        )
      validate_pb_exist_dental(user, params, changeset, product_base)
    end
  end

  defp validate_pb_exist_dental(user, params, changeset, nil) do
    changeset_with_error = error_renderer_api(changeset, :product_base, "Plan Base can't be blank.")
    {:error, changeset_with_error}
  end
  defp validate_pb_exist_dental(user, params, changeset, product_base) when product_base == "" do
    changeset_with_error = error_renderer_api(changeset, :product_base, "Empty string is not accepted. Please enter 'Benefit-based' or 'Exclusion-based'.")
    {:error, changeset_with_error}
  end
  defp validate_pb_exist_dental(user, params, changeset, product_base) when product_base != "benefit-based" do
    changeset_with_error = error_renderer_api(changeset, :product_base, "'#{product_base}' is invalid. Please enter 'Benefit-based'.")
    {:error, changeset_with_error}
  end
  defp validate_pb_exist_dental(user, params, changeset, product_base) do
    product_base = String.downcase(product_base)
    validate_benefit_based_dental(user, params)
  end

  defp validate_benefit_based_dental(user, params) do
    data = %{}

    general_types = %{
      product_base: :string,
      member_type: {:array, :string}
    }

    changeset =
      {data, general_types}
      |> cast(params, Map.keys(general_types))
      |> validate_required([
        :product_base,
        :member_type
      ])

    changeset =
      if changeset.valid?, do: ApiProductContext.validate_member_type(changeset, :member_type), else: changeset

      if changeset.valid?, do: validate_benefit_based_dental_lvl1(changeset, params), else: {:error, changeset}
  end

  defp validate_benefit_based_dental_lvl1(changeset, params) do
    param_validator = ApiProductContext.validate_params(
      Map.keys(params),
      "Benefit-based",
      changeset.changes[:member_type],
      "No",
      "Principal"
    )

    if param_validator do
      data = %{}
      general_types = %{
        code: :string,
        name: :string,
        description: :string,
        product_category: :string,
        product_base: :string,
        dental_plan_limit_amount: :integer,
        standard_product: :string,
        dental_funding_arrangement: :string,
        mode_of_payment: :string,
        mode_of_payment_type: :string,
        type_of_payment: :string,
        capitation_fee: :integer,
        member_type: {:array, :string},
        benefit: {:array, :map},
        facility: {:array, :map},
        risk_share: {:array, :map},
        loa_validity: :integer,
        loa_validity_type: :string,
        special_handling_type: :string,
        limit_amount: :integer,
        plan_code: :string
      }

      params =
        params
        |> Map.put("dental_plan_limit_amount", params["limit_amount"])
        |> Map.put("plan_code", params["code"])

      changeset =
        {data, general_types}
        |> cast(params, Map.keys(general_types))
        |> validate_required([
          :name,
          :code,
          # :description,
          :product_category,
          :product_base,
          # :dental_plan_limit_amount,
          :standard_product,
          :dental_funding_arrangement,
          :mode_of_payment,
          :mode_of_payment_type,
          :type_of_payment,
          :member_type,
          :benefit,
          :facility,
          :loa_validity,
          :loa_validity_type,
          :special_handling_type,
          :plan_code
        ])
        |> ApiProductContext.validate_list_fields(:product_category, ["dental plan"])
        |> ApiProductContext.validate_list_fields(:product_base, ["benefit-based"])
        |> ApiProductContext.validate_list_fields(:dental_funding_arrangement, ["full risk", "aso"])
        |> ApiProductContext.validate_list_fields(:loa_validity_type, ["days", "months"])
        |> ApiProductContext.validate_list_fields(:type_of_payment, ["built-in", "charge to aso", "separate fee"])
        |> ApiProductContext.validate_list_fields(:mode_of_payment, ["capitation", "per_availment", "per availment"])
        |> ApiProductContext.validate_list_fields(:mode_of_payment_type, ["pay on first availment", "pay for active member", "loa facilitated", "reimbursement", "loa facilitated, reimbursement"])
        |> ApiProductContext.validate_list_fields(:standard_product, ["yes", "no"])
        |> ApiProductContext.validate_list_fields(:special_handling_type, ["fee for service", "aso override", "corporate guarantee"])
        |> validate_inclusion(:loa_validity, 1..999, message: "should be 1 - 999 value")
        |> validate_length(:benefit, min: 1, message: "at least one is required")
        |> validate_length(:name, max: 80)
        |> validate_length(:description, max: 150)
        |> validate_inclusion(:dental_plan_limit_amount, 1..99999999, message: "should be 1 - 99,999,999 value")
        |> validate_inclusion(:capitation_fee, 1..99999999, message: "should be 1 - 99,999,999 value")

      if changeset.valid? do
        changeset |> validate_benefit_based_lvl1_2()
      else
        {:error, changeset}
      end
    else
      {:error, changeset}
    end
  end

  defp validate_benefit_based_lvl1_2(changeset) do
    benefit_param = get_field(changeset, :benefit)
    errors =
      benefit_param
      |> Enum.with_index(1)
      |> validate_benefit_params([])

    if Enum.empty?(errors) do
      changeset |> validate_benefit_based_level2()
    else
      errors = Enum.join(errors, ", ")
      {:error, add_error(changeset, :benefit, errors)}
    end
  end

  defp validate_benefit_params([{params, index} | tails], errors) do
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
      validate_benefit_params(tails, errors)
    else
      error = UtilityContext.changeset_errors_to_string(changeset.errors)
      validate_benefit_params(tails, errors ++ ["Benefit row #{index} errors (#{error})"])
    end
  end

  defp validate_benefit_params([], errors), do: errors

  defp validate_benefit_code(changeset) do
    with true <- Map.has_key?(changeset.changes, :code) do
      benefit = ApiProductContext.get_benefit(changeset.changes.code)
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
      if not Enum.member?(params, "DENTL") do
        add_error(changeset, :benefit_coverage, "is not Dental")
      else
        if Enum.count(bc) == Enum.count(params) do
          changeset
        else
          add_error(changeset, :benefit_coverage, "is invalid")
        end
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
      nc =
      changeset.changes.coverage
      |> Enum.map(&(validate_coverage(&1, bc)))
      |> List.first()

         if nc.valid? do
           changeset
         else
           nc
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
      benefit_limit_type: :string,
      benefit_limit_value: :string,
      code: {:array, :string},
      limit_classification: :string,
      limit_area_type: {:array, :string},
      limit_area: {:array, :string}
    }
    coverage_params =
      coverage_params
      |> Map.put("benefit_limit_type", coverage_params["limit_type"])
      |> Map.put("benefit_limit_value", coverage_params["limit_value"])

    changeset =
      {%{}, fields}
      |> cast(coverage_params, Map.keys(fields))
      |> validate_subset(:code, benefit_coverages, message: "is invalid")
      |> validate_required([
        :code,
        :benefit_limit_value
      ])
      |> validate_inclusion(:limit_type, [
        "Plan Limit Percentage",
        "Peso",
        "Session",
        "Tooth",
        "Quadrant",
        "Area"
      ], message: "is invalid")
      |> validate_inclusion(:limit_classification, [
        "Per Transaction",
        "Per Coverage Period"
      ], message: "is invalid")
      |> validate_limit_value()
      |> validate_limit_type()
  end

  defp validate_limit_value(%{
    changes: %{
      limit_type: "Area"
    }
  } = changeset) do
    changeset
    |> validate_required(:limit_area_type)
    |> validate_length(:limit_area_type, min: 1, message: "at least one is required")
    |> capitalize_list(:limit_area_type)
    |> capitalize_list(:limit_area)
    |> validate_subset(:limit_area_type, ["Quadrant", "Site"], message: "only Quadrant and Site is accepted")
    |> validate_limit_area()
  end

  defp validate_limit_area(changeset) do
    with true <- Map.has_key?(changeset.changes, :limit_area_type),
         true <- Enum.member?(changeset.changes.limit_area_type, "Site")
    do
      changeset
      |> validate_required(:limit_area)
      |> validate_length(:limit_area, min: 1, message: "at least one is required")
      |> validate_subset(:limit_area, [
        "Upper inner lip",
        "Lower inner lip",
        "Cheek area",
        "Palatal area",
        "Tongue",
        "Floor of the mouth"
      ], message: "is invalid")
    else
      _ ->
        changeset
    end
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
      add_error(changeset, :benefit_limit_value, "should be 1-100")
    end
  end

  defp validate_limit_value(%{
    changes: %{
      limit_type: "Session",
      limit_value: limit_value
    }
  } = changeset) do
    with true <- ApiProductContext.validate_numbers(limit_value),
         {:ok} <- validate_session_amount(limit_value)
    do
      changeset
    else
      false ->
        add_error(changeset, :benefit_limit_value, "is invalid")
      {:error} ->
        add_error(changeset, :benefit_limit_value, "should be at most 3 numeric character(s)")
      _ ->
        add_error(changeset, :benefit_limit_value, "is invalid")
    end
  end

  defp validate_session_amount(limit_value) do
    if String.to_integer(limit_value) > 0 and String.to_integer(limit_value) <= 999 do
      {:ok}
    else
      {:error}
    end
  end

  defp validate_limit_value(%{
    changes: %{
      limit_type: "Peso",
      limit_value: limit_value
    }
  } = changeset) do
    amount_changeset = validate_format(changeset, :limit_value, ~r/^(?!\.?$)[1-9]\d{0,5}(\.\d{0,2})?$/)
    if amount_changeset.valid? do
      changeset
    else
      add_error(amount_changeset, :benefit_limit_amount, "should be 1 - 99,999,999 value")
    end
  end

  defp validate_limit_value(%{
    changes: %{
      limit_type: "Tooth",
      limit_value: limit_value
    }
  } = changeset) do
    with true <- ApiProductContext.validate_numbers(limit_value),
         {:ok} <- validate_tooth_amount(limit_value)
    do
      changeset
    else
      false ->
        add_error(changeset, :benefit_limit_value, "is invalid")
      {:error} ->
        add_error(changeset, :benefit_limit_value, "should be at most 2 numeric character(s)")
      _ ->
        add_error(changeset, :benefit_limit_value, "is invalid")
    end
  end

  defp validate_tooth_amount(limit_value) do
    if String.to_integer(limit_value) > 0 and String.to_integer(limit_value) <= 99 do
      {:ok}
    else
      {:error}
    end
  end

  defp validate_limit_value(%{
    changes: %{
      limit_type: "Quadrant",
      limit_value: limit_value
    }
  } = changeset) do
    with true <- ApiProductContext.validate_numbers(limit_value),
         {:ok} <- validate_quadrant_amount(limit_value)
    do
      changeset
    else
      false ->
        add_error(changeset, :benefit_limit_value, "is invalid")
      {:error} ->
        add_error(changeset, :benefit_limit_value, "should be numbers 1 to 4 only")
      _ ->
        add_error(changeset, :benefit_limit_value, "is invalid")
    end
  end

  defp validate_quadrant_amount(limit_value) do
    if String.to_integer(limit_value) > 0 and String.to_integer(limit_value) <= 4 do
      {:ok}
    else
      {:error}
    end
  end

  defp validate_limit_value(changeset), do: changeset

  defp generate_string_list do
    for x <- 1..100, do: Integer.to_string(x)
  end

  defp validate_limit_type(changeset) do
    with true <- Map.has_key?(changeset.changes, :code),
         false <- Enum.member?(changeset.changes.code, "ACU")
    do
      validate_required(changeset, :benefit_limit_type)
    else
      _ ->
        changeset
    end
  end

  defp validate_benefit_based_level2(changeset) do
    # Validates product category and exclusions.

    changeset =
      changeset
      |> validate_dental_category()
      |> validate_duplicate_benefits()

    if changeset.valid? do
      validate_benefit_based_level3(changeset)
    else
      {:error, changeset}
    end
  end

  defp validate_dental_category(changeset) do
    # Validates Product Category

    if changeset.changes[:product_category] == "Dental Plan" do
      if changeset.changes[:product_base] != "Benefit-based" do
        add_error(changeset, :product_category, "Only Benefit-based is allowed in Dental Plan.")
      else
        changeset
      end
    else
      changeset
    end
  end

  defp validate_duplicate_benefits(changeset) do
    benefit_param = get_field(changeset, :benefit)
    benefit_codes = benefit_codes_from_params(benefit_param)
    list = benefit_codes |> Enum.uniq()
    duplicate_benefit = benefit_codes -- list

    error = for {b, _index} <- Enum.with_index(benefit_codes, 1) do
      if Enum.member?(duplicate_benefit, String.downcase(b)) do
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
      valid_coverages = for b <- benefit_codes do
        record = ApiProductContext.get_benefit(b)
        get_bcc(record)
      end

      valid_coverages =
        valid_coverages
        |> List.flatten
        |> Enum.uniq

      put_change(changeset, :coverage, valid_coverages)
    else
      ApiProductContext.merge_changeset_errors(result, changeset)
    end
  end

  defp get_bcc(nil), do: []
  defp get_bcc(record), do: Enum.map(record.benefit_coverages, &(&1.coverage.code))

  defp benefit_codes_from_params(params) do
    params
    |> Enum.map(&(&1["code"]))
  end

  defp validate_benefit_based_level3(changeset) do
    # Validates benefit
    benefit_param = get_field(changeset, :benefit)
    benefit_codes = benefit_codes_from_params(benefit_param)
    benefits =
      benefit_codes
      |> Enum.filter(&(is_nil(ApiProductContext.get_benefit(&1))))
      |> Enum.uniq()

    if Enum.empty?(benefits) do
      benefit_ids =
        benefit_codes
        |> Enum.map(&(ApiProductContext.get_benefit(&1).id))

      benefit_ids =
        benefit_ids
        |> Enum.map(&(
          BenefitContext.get_benefit(&1).benefit_coverages
          |> Enum.into([], fn(x) -> if x.coverage.name == "Dental",
            do: &1
          end)
        ))

        |> List.flatten()
        |> Enum.filter(fn(b) -> b != nil end)

      if Enum.empty?(benefit_ids) do
        changeset = add_error(changeset, :benefit, "Coverage is not Dental")
      else
        pp_ids =
          benefit_ids
          |> Enum.map(fn(x) ->
            get_benefit_with_procedures(x)
          end)

        if cdt_checker(pp_ids) == false do
          changeset =
            changeset
            |> validate_benefit()
        else
          changeset = add_error(changeset, :benefit, "CDTs are same for benefits selected")
        end
      end
    else
      benefits =
        benefits
        |> Enum.join(", ")

      changeset =
        add_error(changeset, :benefit, "#{benefits} is not existing")
    end

    if changeset.valid? do
      validate_benefit_based_level4(changeset)
    else
      {:error, changeset}
    end
  end

  defp cdt_checker([head | tails]) do
    tails =
      tails
      |> List.flatten()
    Enum.any?(head, fn x -> x in tails end)
  end

  defp get_benefit_with_procedures(b_id) do
    Benefit
    |> join(:inner, [b], bp in BenefitProcedure, b.id == bp.benefit_id)
    |> join(:inner, [b, bp], pp in PayorProcedure, bp.procedure_id == pp.id)
    |> where([b, bp, pp], b.id == ^b_id)
    |> select([b, bp, pp], pp.id)
    |> Repo.all()
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
      |> validate_plan_code()
      |> validate_dental_facility()
      |> ApiProductContext.validate_facility()
      |> validate_dental_risk_share()
      |> validate_mode_of_payment()
      |> validate_dfa()

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
          record = ApiProductContext.get_benefit(b)
          if not is_nil(record) do
            check_b_dental_plan(changeset, record, product_category, b)
          else
            check_valid_benefit(changeset, b)
          end
        end

        result =
          result
          |> List.flatten
          |> Enum.uniq
          |> List.delete(nil)

        if Enum.empty?(result) do
          validate_benefit_level2(changeset)
        else
          ApiProductContext.merge_changeset_errors(result, changeset)
        end
      else
        add_error(changeset, :benefit, "At least one benefit code is required.")
      end
    else
      add_error(changeset, :benefit, "Invalid paramters.")
    end
  end

  defp check_b_dental_plan(changeset, record, product_category, b) do
    if product_category == "Dental Plan" do
      coverages = for bc <- record.benefit_coverages do
        bc.coverage.name
      end

      coverage =
        coverages
        |> List.delete("Dental")

      if not Enum.empty?(coverage) do
        add_error(
          changeset,
          :benefit,
          "#{b} is not Dental. Dental is the only coverage that is accepted in Dental Plans."
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

  defp validate_benefit_level2(changeset) do
    with true <- validate_benefit_inner_limit(changeset),
         true <- validate_benefit_inner_limit_from_params(changeset)
    do
      validate_benefit_level3(changeset)
    else
      {:greater_than_limit_amount} ->
        add_error(changeset, :benefit, "Limits of benefit entered is greater than plan's limit amount.")
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
        get_values(b, limit_amount)
      end)
    if Enum.member?(benefit_limits, false) do
      {:greater_than_limit_amount}
    else
      true
    end
  end

  defp get_values(params, limit_amount) do
        amounts =
          Enum.map(params["coverage"], fn(coverage) ->
            if coverage["limit_type"] == "Peso" do
              Decimal.new(coverage["limit_value"])
            else
              Decimal.new("0")
            end
          end)
        total_amount = Enum.reduce(amounts, Decimal.new(0), &Decimal.add/2)
        result = Decimal.compare(get_plan_limit_amount(limit_amount, total_amount), total_amount)
        if result == Decimal.new(1) or result == Decimal.new(0) do
          true
        else
          false
        end
  end

  def get_plan_limit_amount(nil, total_amount), do: total_amount
  def get_plan_limit_amount(limit_amount, _total_amount), do: Decimal.new(limit_amount)

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
        record = ApiProductContext.get_benefit(b)
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
      ApiProductContext.merge_changeset_errors(result, changeset)
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

      limit_amount = get_field(changeset, :limit_amount)
      if is_nil(benefit_limit) do
        true
      else
        benefit_limit_result = [] ++ for bl <- benefit_limit do
          result = Decimal.compare(get_plan_limit_amount(limit_amount, bl), bl)
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

  defp validate_dental_facility(changeset) do
    facility_rec =
      changeset.changes[:facility]
      |> List.first()

    fc = product_coverage_type_checker(facility_rec["type"], facility_rec, changeset)
    cond do
      fc == {:ok} && facility_rec["type"] == "exception" ->
      lg =
        facility_rec["location_group"]
        |> List.first()

        lg1 = MainProductContext1.get_dental_facilities_by_lg_name(lg)

        if is_nil(lg1) do
          add_error(changeset, :facility, "Location group does not have a dental facility type")
        else
          validate_dental_facility2(changeset, lg1)
        end
      facility_rec["type"] == "inclusion" ->
        validate_sdf(changeset)
      facility_rec["type"] == "exception" ->
        fc
      true ->
        changeset
    end

  end

  defp product_coverage_type_checker("exception", fac, changeset) do
    with true <- Map.has_key?(fac, "location_group"),
         false <- Enum.empty?(fac["location_group"])
    do
      {:ok}
    else
      false ->
        add_error(changeset, :facility, "location group is required")
      true ->
        add_error(changeset, :facility, "location group is required")
      _ ->
        add_error(changeset, :facility, "location group is required")
    end
  end
  defp product_coverage_type_checker("inclusion", fac, changeset) do
    with true <- Map.has_key?(fac, "code"),
         false <- Enum.empty?(fac["code"])
    do
      {:ok}
    else
      false ->
        add_error(changeset, :facility, "code is required")
      true ->
        add_error(changeset, :facility, "code is required")
      _ ->
        add_error(changeset, :facility, "code is required")
    end
  end
  defp product_coverage_type_checker(pc_type, fac, changeset),
    do: add_error(changeset, :facility, "coverage type is invalid")

  defp validate_dental_facility2(changeset, lg1) do
    dlgfc = Enum.map(lg1.facility_location_group, &(&1.facility.code))
    df =
      changeset.changes[:facility]
      |> Enum.map(&(&1["code"]))
      |> List.flatten()

    nedf = Enum.filter(df, fn f -> !Enum.member?(dlgfc, f) end)
    if not Enum.empty?(nedf) do
      nedf = Enum.join(nedf, ", ")
      add_error(changeset, :facility, "#{nedf} does not belong to the location group")
    else
      changeset
    end
  end

  def validate_sdf(changeset) do
    df =
      changeset.changes[:facility]
      |> Enum.map(&(&1["code"]))
      |> List.flatten()

    dfc =
      Facility
      |> join(:inner, [f], d in Dropdown, f.ftype_id == d.id)
      |> where([f, d], d.text == "DENTAL PROVIDER" or d.text == "DENTAL CLINIC")
      |> select([f], f.code)
      |> Repo.all()

    if Enum.all?(df, fn(x) ->
      Enum.member?(dfc, x)
    end)
    do
      changeset
    else
      add_error(changeset, :facility, "one or more facility code is not Dental")
    end
  end

  defp validate_dental_risk_share(changeset) do
    if Map.has_key?(changeset.changes, :risk_share) do
      ApiProductContext.validate_risk_share(changeset)
    else
      changeset
    end
  end

  defp validate_mode_of_payment(changeset) do
    mop = changeset.changes[:mode_of_payment]
    if mop == "Capitation" do
      changeset
      |> validate_capitation()
      |> validate_capitation_fee2()
    else
      changeset
      |> validate_per_availment()
      |> validate_capitation_fee()
    end
  end

  defp validate_capitation(changeset) do
    value = String.downcase(changeset.changes[:mode_of_payment_type])
    types = ["pay on first availment", "pay for active member"]
    if not Enum.member?(types, value) do
      add_error(changeset, :mode_of_payment_type, "Is not valid. Should be one of the following: Pay on first availment, Pay for Active member")
    else
      changeset
    end
  end

  defp validate_per_availment(changeset) do
    value = String.downcase(changeset.changes[:mode_of_payment_type])
    types = ["loa facilitated", "reimbursement", "loa facilitated, reimbursement"]
    if not Enum.member?(types, value) do
      add_error(changeset, :mode_of_payment_type, "is invalid")
    else
      changeset
    end
  end

  defp validate_capitation_fee(changeset) do
    if Map.has_key?(changeset.changes, :capitation_fee) or not is_nil(changeset.changes[:capitation_fee]) do
      add_error(changeset, :capitation_fee, "is not available")
    else
      changeset
    end
  end

  defp validate_capitation_fee2(changeset) do
    if not Map.has_key?(changeset.changes, :capitation_fee) or is_nil(changeset.changes[:capitation_fee]) do
      add_error(changeset, :capitation_fee, "is required")
    else
      changeset
    end
  end

  defp validate_dfa(changeset) do
    dfa = String.downcase(changeset.changes[:dental_funding_arrangement])
    validate_dfa_type(dfa, changeset)
  end

  defp validate_dfa_type(dfa, changeset) when dfa == "full risk" do
    value = String.downcase(changeset.changes[:type_of_payment])
    types = ["built-in", "separate fee"]
    if not Enum.member?(types, value) do
      add_error(changeset, :type_of_payment, "Is not valid. Should be one of the following: Built in, Separate fee")
    else
      changeset
    end
  end
  defp validate_dfa_type(dfa, changeset) when dfa == "aso" do
    value = String.downcase(changeset.changes[:type_of_payment])
    types = ["built-in", "separate fee", "charge to aso"]
    if not Enum.member?(types, value) do
      add_error(changeset, :type_of_payment, "Is not valid. Should be one of the following: Built in, Separate fee, Charge to ASO")
    else
      changeset
    end
  end

  defp validate_plan_code(changeset) do
    pcode =
      changeset.changes[:code]
      |> get_plan_code(changeset)
  end

  defp get_plan_code(nil, changeset), do: changeset
  defp get_plan_code(pcode, changeset) do
    pcode = String.downcase(pcode)
    plan =
      Product
      |> where([p], fragment("lower(?)", p.code) == ^pcode)
      |> select([p], p.id)
      |> Repo.all()

    if not Enum.empty?(plan) do
      add_error(changeset, :plan_code, "already exists")
    else
      changeset
    end
  end

  # End of the validation of benefit based products.

  defp error_renderer_api(changeset, key, message), do: add_error(changeset, key, message)

  def insert_dental_plan(user, params) do
    with {:ok, changeset} <- validate_insert_dental(user, params),
         {:ok, product} <- insert_product(user, params),
         {:ok} <- insert_product_benefits(product, params, params["benefit"], user),
         {:ok} <- insert_product_benefit_limit(product, params, params["benefit"]),
         {:ok} <- insert_product_coverage_lg(product, params["facility"]),
         {:ok} <- insert_product_coverage_facility(product, params, params["facility"]),
         {:ok} <- insert_product_coverage_risk_share(product, params)
    do
      product = MainProductContext1.get_product_dental_by_code(product.code)
      {:ok, product}
    else
      {:error, changeset} ->
        {:error, changeset}
      {:product_base_invalid} ->
        {:product_base_invalid}
      _ ->
        {:error_creating_product}
    end
  end

  defp insert_product(user, params) do
    maxicare = Repo.get_by(Payor, name: "Maxicare")
    params
    |> transforms_mode_of_payment_type()
    |> transforms_member_type()
    |> Map.put("created_by_id", user.id)
    |> Map.put("updated_by_id", user.id)
    |> Map.put("step", "8")
    |> Map.put("payor_id", maxicare.id)
    |> Map.put("type_of_payment_type", params["type_of_payment"])
    |> insert_dental_general()
  end

  defp transforms_mode_of_payment_type(params) do
    mop = String.downcase(params["mode_of_payment_type"])
    cond do
      mop == "pay on first availment" || mop == "pay for active member" ->
        params =
          params
          |> Map.put("capitation_type", params["mode_of_payment_type"])
      mop == "loa facilitated, reimbursement" || mop == "loa facilitated" || mop == "reimbursement" ->
        params =
          params
          |> Map.put("availment_type", params["mode_of_payment_type"])
      true ->
        params
    end
  end

  defp transforms_member_type(params) do
    member_type =
      params["member_type"]
      |> Enum.join(", ")

    params =
      params
      |> Map.put("limit_applicability", member_type)
  end

  defp insert_dental_general(params) do
    %Product{}
    |> Product.changeset_dental_api(params)
    |> Repo.insert()
  end

  def insert_product_benefits(product, params, benefits, user) do
    benefit_codes =
      benefits
      |> ApiProductContext.benefit_codes_from_params_without_limit()

    benefit_ids = Enum.map(benefit_codes, &(ApiProductContext.get_benefit_id_by_code(&1)))
    params =
      params
      |> Map.put("benefit_ids", benefit_ids)

    MainProductContext1.set_product_benefits(product, params["benefit_ids"], user.id)
  end

  def insert_product_benefit_limit(product, params, benefits) do
    benefits =
      benefits
      |> ApiProductContext.filter_benefits_with_limit()
      |> Enum.map(&({&1, ApiProductContext.get_benefit_id_by_code(&1["code"])}))

    ApiProductContext.set_product_benefits_with_limit(product, benefits)
  end

  def insert_product_coverage_lg(product, facility) do
    type =
      facility
      |> Enum.map(fn(f) ->
        f["type"]
      end)
      |> List.flatten
      |> List.first()

    lg =
      facility
      |> Enum.map(fn(f) ->
        f["location_group"]
      end)
      |> List.flatten()
      |> List.first()

    set_pclg(type, lg, product, facility)
  end

  defp set_pclg(type, nil, product, facility), do: {:ok}
  defp set_pclg(type, "", product, facility), do: {:ok}
  defp set_pclg(type, lg, product, facility) do
    lg = MainProductContext1.get_dental_facilities_by_lg_name(lg)
    coverage_id =
      facility
      |> Enum.map(fn(f) ->
        f["coverage"]
      end)
      |> List.flatten()
      |> List.first()
      |> ApiProductContext.get_coverage_by_name()

    product_coverage_id = ApiProductContext.get_product_coverage_id(coverage_id, product.id)

    pclg_params = %{
      "product_coverage_id" => product_coverage_id,
      "location_group_id" => lg.id
    }

    MainProductContext1.insert_or_update_pclg(pclg_params)
    {:ok}
  end

  def insert_product_coverage_facility(product, params, facility) do
    for f <- facility do
      coverage_id = ApiProductContext.get_coverage_by_name(f["coverage"])
      product_coverage_id = ApiProductContext.get_product_coverage_id(coverage_id, product.id)
      product_coverage = ApiProductContext.get_product_coverage(product_coverage_id)

      f_params = %{
        type: f["type"] |> ApiProductContext.convert_type(),
        coverage_id: coverage_id,
        product_id: product.id
      }

      if not is_nil(f["code"]) do
        facility_ids = Enum.map(f["code"], fn(code) ->
          ApiProductContext.get_facility_by_code(code)
        end)

        location_group = f["location_group"]
        MainProductContext1.set_product_facility(product_coverage_id, facility_ids)
      end

      # MainProductContext1.add_facility_by_location_group(location_group, product_coverage_id)
      MainProductContext1.set_product_coverage_type(product_coverage, f_params)
    end
    |> Enum.member?(nil)
    |> validate_pcf()
  end

  defp validate_pcf(true), do: {:error}
  defp validate_pcf(false), do: {:ok}

  def insert_product_coverage_risk_share(product, params) do
    with true <- Map.has_key?(params, "risk_share") do
      for risk_share <- params["risk_share"] do
        coverage_id = ApiProductContext.get_coverage_by_name(risk_share["coverage"])
        product_coverage_id = ApiProductContext.get_product_coverage_id(coverage_id, product.id)

        product_coverage = ApiProductContext.get_product_coverage(product_coverage_id)
        # pcd_rs_id = product_coverage.product_coverage_dental_risk_share.id
        # pcdrs_struct = MainProductContext1.get_product_coverage_dental_risk_share(pcd_rs_id)

        rs_params = %{
          "asdf_type" => risk_share["asdf_type"],
          "asdf_value" => risk_share["asdf_value"],
          "asdf_special_handling" => risk_share["asdf_special_handling"],
          "product_coverage_id" => product_coverage_id
        }
        if rs_params["asdf_type"] == "Copayment" do
          rs_params =
            rs_params
            |> Map.put("asdf_amount", rs_params["asdf_value"])
        else
          rs_params =
            rs_params
            |> Map.put("asdf_percentage", rs_params["asdf_value"])
        end

        {:ok, pcdrs_struct} = MainProductContext1.create_product_coverage_dental_risk_share(rs_params)

        if Map.has_key?(risk_share, "exempted_facilities") do
          for facility <- risk_share["exempted_facilities"] do
            facility_id = ApiProductContext.get_facility_by_code(facility["facility_code"])
            params = %{
              "facility_id" => facility_id,
              "product_coverage_dental_risk_share_id" => pcdrs_struct.id,
              "sdf_type" => facility["sdf_type"],
              "sdf_value" => facility["sdf_value"],
              "product_dental_risk_share_facility_id" => "",
              "product_dental_risk_share_id" => pcdrs_struct.id,
              "sdf_special_handling" => facility["sdf_special_handling"]
            }

            if params["sdf_type"] == "Copayment" do
              params =
                params
                |> Map.put("sdf_amount", params["sdf_value"])
            else
              params =
                params
                |> Map.put("sdf_percentage", params["sdf_value"])
            end

            {:ok, pcdrsf} = MainProductContext1.set_product_dental_risk_share_facility(params)
          end
        end
      end
      {:ok}
    else
      false ->
        {:ok}
      _ ->
        {:ok}
    end
  end

  def get_product_dental(conn, product_code) do
    with %Product{} = product <- MainProductContext1.get_product_dental_by_code(product_code) do
      {:ok, product}

    else
      {:error, changeset} ->
        {:error, changeset}

      _ ->
         {:error}
    end
  end

  defp capitalize(changeset, key) do
    with true <- Map.has_key?(changeset.changes, key) do
      string =
        changeset.changes[key]
        |> String.split(" ")
        |> Enum.map(&(String.capitalize(&1)))
        |> Enum.join(" ")
      changeset
      |> put_change(key, string)
    else
      _ ->
        changeset
    end
  end

  defp capitalize_list(changeset, key) do
    with true <- Map.has_key?(changeset.changes, key),
         true <- is_list(changeset.changes[key])
    do
      list =
        changeset.changes[key]
        |> Enum.map(fn(string) ->
          string
          |> String.split(" ")
          |> Enum.map(&(String.capitalize(&1)))
          |> Enum.join(" ")
        end)
      changeset
      |> put_change(key, list)
    else
      _ ->
        changeset
    end
  end

end
