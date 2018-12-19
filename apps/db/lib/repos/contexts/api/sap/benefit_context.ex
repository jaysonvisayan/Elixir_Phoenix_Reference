defmodule Innerpeace.Db.Base.Api.Sap.BenefitContext do
  import Ecto.{Query}, warn: false

  @moduledoc :false

  alias Ecto.Changeset
  alias Innerpeace.Db.Base.BenefitContext, as: MainBenefitContext
  alias Innerpeace.Db.Base.Api.BenefitContext, as: ApiBenefitContext
  alias Innerpeace.Db.{
    Repo,
    Schemas.Benefit,
    Schemas.Coverage,
    Schemas.BenefitCoverage,
    Schemas.BenefitProcedure,
    Schemas.BenefitLimit,
    Schemas.Procedure,
    Schemas.PayorProcedure,
    Base.CoverageContext,
    Base.Api.UtilityContext
  }

  def create_sap_dental(user, params) do
    with {:ok, changeset} <- validate_params(params),
         changeset <- transform_data(changeset),
         {:ok, benefit} <- insert_sap_benefit_dental(changeset, user),
         :ok <- insert_benefit_coverages(benefit.id, changeset),
         :ok <- insert_benefit_cdt(benefit.id, changeset),
         :ok <- insert_benefit_limits(benefit.id, changeset)
    do
      {:ok, benefit |> preload_sap_dental()}
    else
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp validate_params(params) do
    fields = %{
      code: :string,
      name: :string,
      category: :string,
      type: :string,
      coverages: {:array, :string}
    }

    {%{}, fields}
    |> Changeset.cast(params, Map.keys(fields))
    |> Changeset.validate_required([
      :code,
      :name,
      :category,
      :type,
      :coverages
    ])
    |> Changeset.validate_length(:code, max: 50)
    |> Changeset.validate_length(:name, max: 80)
    |> Changeset.validate_format(:code, ~r/^[ a-zA-Z0-9-_.]*$/)
    |> validate_field_choices(:category, [
      "riders",
      "health"
    ]) ## for now lets stick to riders only
    |> validate_field_choices(:type, [
      "policy",
      "availment"
    ])
    |> validate_benefit_code()
    |> validate_coverages() ## only dental is our concern coverage
    |> validate_type(:type, params)
    |> changeset_valid?()
  end

  defp validate_benefit_code(%{changes: %{code: code}} = changeset) do
    if is_nil(check_benefit_code(code)) do
      changeset
    else
      Changeset.add_error(changeset, :code, "is already taken")
    end
  end

  defp validate_benefit_code(changeset), do: changeset

  defp check_benefit_code(code) do
    Benefit
    |> where([b], fragment("LOWER(?)", b.code) == fragment("LOWER(?)", ^code))
    |> limit(1)
    |> Repo.one()
  end

  defp validate_field_choices(changeset, field, choices) do
    with true <- changeset.changes |> Map.has_key?(field),
         {:ok, changeset} <- check_field_value(changeset, field, choices)
    do
      changeset
    else
      false ->
        changeset
      {:error, changeset} ->
        changeset
    end
  end

  defp check_field_value(changeset, field, choices) do
    changeset.changes[field]
    |> String.downcase()
    |> check_field_value(choices)
    |> is_valid?(changeset, field, choices)
  end
  defp check_field_value(value, choices), do: Enum.member?(choices, value)

  defp is_valid?(true, changeset, field, choices), do: {:ok, changeset}
  defp is_valid?(false, changeset, field, choices) do
    {:error,
      changeset
      |> Changeset.add_error(
        field,
        "'#{changeset.changes[field]}' is not valid. The only allowed value is [#{choices
        |> Enum.map(&(&1
        |> String.capitalize()))
        |> Enum.join(", ")}]")
    }
  end

  def validate_type(changeset, field, params) do
    with true <- changeset.changes |> Map.has_key?(field) do
      case changeset.changes[field] |> String.downcase() do
        "availment" ->
          changeset |> set_additional_params(params)
        "policy" ->
          changeset |> check_unnecessary_params(params)
        _ ->
          changeset
      end
    else
      false ->
        changeset
    end
  end

  defp check_unnecessary_params(changeset, params) do
    valid_keys = %{
      code: :string,
      name: :string,
      category: :string,
      type: :string,
      coverages: {:array, :string}
    }
    |> Map.new(fn {k, v} -> {Atom.to_string(k), v} end)
    |> Map.keys()
    |> subtract_keys(params |> Map.keys())
    |> if_empty?(changeset)
  end
  defp subtract_keys(valid_keys, params_keys), do: params_keys -- valid_keys
  defp if_empty?([], changeset), do: changeset
  defp if_empty?(unwanted_keys, changeset) do
    data = %{}
    general_types = %{product: :string}

    dummy =
      {data, general_types}
      |> Changeset.cast(%{sample: "sample"}, Map.keys(general_types))

    unwanted_keys
    |> Enum.map(&(dummy |> Changeset.add_error(&1, "'#{&1}' is not belong to the list of accepted parameters.")))
    |> merge_changeset_errors(changeset)
  end

  defp if_empty_v2?([], changeset), do: changeset
  defp if_empty_v2?(unwanted_keys, changeset) do
    data = %{}
    general_types = %{product: :string}

    dummy =
      {data, general_types}
      |> Changeset.cast(%{sample: "sample"}, Map.keys(general_types))

    unwanted_keys
    |> Enum.map(&(dummy |> Changeset.add_error(&1, "is not belong to the list of accepted parameters.")))
    |> merge_changeset_errors(changeset)
  end

  defp set_additional_params(changeset, params) do
    fields = %{
      loa_facilitated: :boolean, default: false,
      reimbursement: :boolean, default: false,
      frequency: :string,
      cdt: {:array, :string},
      limits: {:array, :map}
    }
    {%{}, fields}
    |> Changeset.cast(params, Map.keys(fields))
    |> Changeset.validate_required([
      :frequency,
      :cdt,
      :limits
    ])
    |> Changeset.merge(changeset)
    |> validate_field_choices(:frequency, ["annually", "semi-annually", "quarterly", "monthly"])
    |> validate_cdt()
    |> validate_limits()
    |> validate_availment_type()
  end

  defp validate_availment_type(%{
    changes: %{
      reimbursement: reimbursement,
      loa_facilitated: loa_facilitated
    }
  } = changeset) do
    if Enum.member?([reimbursement, loa_facilitated], true) do
      changeset
    else
      Changeset.add_error(changeset, :availment_type, "at least one is required")
    end
  end

  defp validate_availment_type(%{
    changes: %{
      reimbursement: reimbursement
    }
  } = changeset) do
    if Enum.member?([reimbursement], true) do
      changeset
    else
      Changeset.add_error(changeset, :availment_type, "at least one is required")
    end
  end

  defp validate_availment_type(%{
    changes: %{
      loa_facilitated: loa_facilitated
    }
  } = changeset) do
    if Enum.member?([loa_facilitated], true) do
      changeset
    else
      Changeset.add_error(changeset, :availment_type, "at least one is required")
    end
  end

  defp validate_availment_type(changeset) do
    Changeset.add_error(changeset, :availment_type, "at least one is required")
  end

  #################################  start: validate_coverages  ##################################
  @docp """
  1. A valid coverage value.
  2. To match an empty string inside array value of coverages parameter.
  3. To match an empty array value of coverages parameter.
  4. To match a non 'DENTL' value.
  5. To match invalid format of coverages parameter
  """
  defp validate_coverages(%{changes: %{coverages: ["DENTL"]}} = changeset), do: changeset # 1
  defp validate_coverages(%{changes: %{coverages: [""]}} = changeset) do                  # 2
    changeset |> Changeset.add_error(:coverages, "Must have atleast one coverage.")
  end
  defp validate_coverages(%{changes: %{coverages: []}} = changeset) do                    # 3
    changeset |> Changeset.add_error(:coverages, "Must have atleast one coverage.")
  end
  defp validate_coverages(%{changes: %{coverages: _unused}} = changeset) do               # 4
    changeset |> Changeset.add_error(:coverages, "It must be 'DENTL' coverage only.")
  end
  defp validate_coverages(changeset), do: changeset                                       # 5
  #################################  end: validate_coverages  ####################################
  #||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
  ###################################  start: validate_cdt  ######################################
  defp validate_cdt(%{changes: %{cdt: [""]}} = changeset) do
    changeset |> Changeset.add_error(:cdt, "Must have atleast one cdt.")
  end
  defp validate_cdt(%{changes: %{cdt: []}} = changeset) do
    changeset |> Changeset.add_error(:cdt, "Must have atleast one cdt.")
  end
  defp validate_cdt(%{changes: %{cdt: cdt_list}} = changeset) do
    cdt_list
    |> Enum.with_index(1)
    |> Enum.map(fn({val, index}) -> %{value: val, index: index} |> get_procedure_cdt(changeset) end)
    |> merge_changeset_errors(changeset)
  end
  defp validate_cdt(changeset), do: changeset

  defp get_procedure_cdt(data, changeset) do
    PayorProcedure
    |> join(:left, [pp], p in Procedure, pp.procedure_id == p.id)
    |> join(:left, [pp, p], c in Coverage, p.coverage_id == c.id)
    |> where([pp, p, c], (pp.code == ^data.value and c.code == ^"DENTL"))
    |> Repo.one()
    |> is_cdt_existing?(data, changeset)

  rescue
    _ ->
    changeset |> Changeset.add_error("cdt-row#{data.index}", "#{data.value} is a faulty data")
  end

  defp is_cdt_existing?(%PayorProcedure{} = procedure, data, changeset), do: changeset
  defp is_cdt_existing?(nil, data, changeset) do
    changeset |> Changeset.add_error("cdt-row#{data.index}", "#{data.value} is not existing")
  end
  ################################### end: validate_cdt  #########################################
  #||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
  ################################### start: validate_limits  ####################################
  defp validate_limits(%{changes: %{limits: [""]}} = changeset) do
    changeset |> Changeset.add_error(:limits, "Must have atleast one limit.")
  end
  defp validate_limits(%{changes: %{limits: []}} = changeset) do
    changeset |> Changeset.add_error(:limits, "Must have atleast one limit.")
  end
  defp validate_limits(%{changes: %{limits: limit_list}} = changeset) do
    limit_list
    |> Enum.with_index(1)
    |> Enum.map(fn({val, index}) ->  %{value: val, index: index} |> cast_limit_params(changeset)  end)
    |> merge_changeset_errors(changeset)
  end
  defp validate_limits(changeset), do: changeset

  defp cast_limit_params(%{value: %{"coverages" => []}} = data, changeset) do
    Changeset.add_error(changeset, :limits, "coverages cant be blank")
  end
  defp cast_limit_params(%{value: %{"coverages" => [""]}} = data, changeset) do
    Changeset.add_error(changeset, :limits, "coverages cant be blank")
  end
  defp cast_limit_params(%{value: %{"coverages" => ["DENTL"]}} = data, changeset) do
    fields = %{
      coverages: {:array, :string},
      limit_type: :string,
    }
    _limit_changeset =
      {%{}, fields}
      |> Changeset.cast(data.value, Map.keys(fields))
      |> Changeset.validate_required([
        :coverages,
        :limit_type
      ])
      |> validate_field_choices(:limit_type, ["peso", "session", "tooth", "area"])
      |> validate_limit_type(data)
      |> consolidate_changesets(changeset)
  end
  defp cast_limit_params(%{value: %{"coverages" => _unused}} = data, changeset) do
    Changeset.add_error(changeset, :limits, "It must be 'DENTL' coverage only")
  end

  defp consolidate_changesets(limit_changeset, changeset) do
    if Enum.empty?(limit_changeset.errors) do
      changeset
    else
      Changeset.add_error(
        changeset,
        :limits,
        limit_changeset.errors
        |> Enum.map(fn({x, {y, z}}) -> "#{x}: #{y}" end)
        |> Enum.join(", ")
      )
    end
  end

  defp validate_limit_type(limit_changeset, data) do
    with true <- limit_changeset.valid?,
         limit_type  <- limit_changeset.changes.limit_type |> String.downcase(),
         limit_changeset <- cast_params_based_on_limit_type(limit_type, limit_changeset, data)
    do
      limit_changeset
    else
      false ->
        limit_changeset
      _ ->
        limit_changeset
    end
  end

  defp cast_params_based_on_limit_type("peso", limit_changeset, data) do
    fields = %{
      limit_amount: :string,
    }
    {%{}, fields}
    |> Changeset.cast(data.value, Map.keys(fields))
    |> Changeset.validate_required([
      :limit_amount
    ])
    |> check_limit_unnecessary_params(data, [
      :coverages, :limit_type, :limit_amount
    ])
    |> validate_decimal()
  end

  defp validate_decimal(%{changes: %{limit_amount: limit_amount}} = changeset) do
    with {:valid_format} <- validate_regex(limit_amount),
         {:valid_comparison} <- validate_comparing(limit_amount),
         {:false} <- validate_if_lt_or_eq_zero(limit_amount)
    do
      changeset
    else
      {:invalid_format} ->
        Changeset.add_error(changeset, :limit_amount, "is invalid")

      {:invalid_comparison} ->
        Changeset.add_error(changeset, :limit_amount, "upto 8 numeric characters only")

      {:true, message} ->
        Changeset.add_error(changeset, :limit_amount, message)
    end
  end

  defp validate_regex(limit_amount) do
    if Regex.match?(~r/^[0-9]*(\.[0-9]{1,2})?$/, limit_amount) do
      {:valid_format}
    else
      {:invalid_format}
    end
  end

  defp validate_comparing(limit_amount) do
    if Decimal.compare(Decimal.new(100_000_000), Decimal.new(limit_amount)) == Decimal.new(1) do
      {:valid_comparison}
    else
      {:invalid_comparison}
    end
  end

  defp validate_if_lt_or_eq_zero(limit_amount) do
    limit =
    0
    |> Decimal.new()
    |> Decimal.compare(Decimal.new(limit_amount))
    |> Decimal.to_integer()

    case limit do
      0 ->
        {:true, "zero value is not accepted"}

      1 ->
        {:true, "0 below value is not accepted"}

      -1 ->
        {:false}
    end
  end

  defp validate_decimal(changeset), do: changeset

  defp cast_params_based_on_limit_type("session", limit_changeset, data) do
    fields = %{
      limit_session: :string,
    }
    {%{}, fields}
    |> Changeset.cast(data.value, Map.keys(fields))
    |> Changeset.validate_required([
      :limit_session
    ])
    |> validate_sessions()
    |> check_limit_unnecessary_params(data, [
      :coverages, :limit_type, :limit_session
    ])
  end

  defp validate_sessions(%{changes: %{limit_session: limit_session}} = changeset) do
    if Enum.member?(generate_string_list(), limit_session) do
      changeset
    else
      Changeset.add_error(changeset, :limit_session, "should be 1-99")
    end
  end

  defp validate_sessions(changeset), do: changeset

  defp generate_string_list do
    for x <- 1..99, do: Integer.to_string(x)
  end

  defp cast_params_based_on_limit_type("tooth", limit_changeset, data) do
    fields = %{
      limit_amount: :string,
      limit_session: :string
    }
    {%{}, fields}
    |> Changeset.cast(data.value, Map.keys(fields))
    |> validate_tooth()
    |> validate_tooth_limit()
    |> validate_decimal()
    |> check_limit_unnecessary_params(data, [
      :coverages, :limit_type, :limit_session, :limit_amount
    ])
  end

  defp validate_tooth_limit(%{changes: %{limit_session: limit_session}} = changeset) do
    if Enum.member?(generate_string_list_tooth(), limit_session) do
      changeset
    else
      Changeset.add_error(changeset, :limit_session, "should be 1-999")
    end
  end

  # defp validate_tooth_limit(%{changes: %{limit_amount: limit_amount}} = changeset) do
  #   with {:valid_format} <- validate_regex(limit_amount),
  #        {:false} <- validate_if_lt_or_eq_zero(limit_amount)
  #   do
  #     changeset
  #   else
  #     {:true, message} ->
  #       Changeset.add_error(changeset, :limit_amount, message)

  #     {:invalid_format} ->
  #       Changeset.add_error(changeset, :limit_amount, "is invalid")
  #   end
  # end

  defp validate_tooth_limit(changeset), do: changeset

  defp generate_string_list_tooth do
    for x <- 1..999, do: Integer.to_string(x)
  end

  defp cast_params_based_on_limit_type("area", limit_changeset, data) do
    fields = %{
      limit_area_type: {:array, :string},
      limit_area: {:array, :string},
    }
    {%{}, fields}
    |> Changeset.cast(data.value, Map.keys(fields))
    |> Changeset.validate_required([
      :limit_area_type
    ])
    |> validate_area()
    |> is_site_selected?(data)
    |> check_limit_unnecessary_params(data, [
      :coverages, :limit_type, :limit_area_type, :limit_area
    ])
  end

  def check_limit_unnecessary_params(changeset, data, valid_keys) do
    valid_keys
    |> Enum.map(fn(v) -> Atom.to_string(v) end)
    |> subtract_keys(data.value |> Map.keys())
    |> if_empty_v2?(changeset)
  end

  ########### start: validation for tooth ###############
  def validate_tooth(tooth_changeset) do
    tooth_changeset
    |> check_tooth_keys()
    |> tooth_amount_and_session_checker(tooth_changeset)
  end
  defp check_tooth_keys(tooth_changeset) do
    [
      Map.has_key?(tooth_changeset.changes, :limit_amount),
      Map.has_key?(tooth_changeset.changes, :limit_session)
    ]
  end
  defp tooth_amount_and_session_checker([true, false], tooth_changeset), do: tooth_changeset
  defp tooth_amount_and_session_checker([false, true], tooth_changeset), do: tooth_changeset
  defp tooth_amount_and_session_checker([true, true], tooth_changeset) do
    tooth_changeset
    |> Changeset.add_error(
      :limit_type_tooth,
      "Only one of the following is required. Enter limit_amount or limit_session." # as per BA-Anne
    )
  end
  defp tooth_amount_and_session_checker([false, false], tooth_changeset) do
    tooth_changeset
    |> Changeset.add_error(
      :limit_type_tooth,
      "At least one of the following is required. Enter limit_amount or limit_session." # as per BA-Anne
    )
  end
  ########### end: validation for tooth #######################################\\\\\

  ########### start: validation for area ###############
  def validate_area(area_changeset) do
    area_changeset.valid? |> cast_params_based_on_area_type(area_changeset)
  end
  defp cast_params_based_on_area_type(false, area_changeset), do: area_changeset
  defp cast_params_based_on_area_type(true, area_changeset) do
    area_changeset.changes.limit_area_type
    |> Enum.map(&(String.downcase(&1)))
    |> Enum.sort()
    |> validate_limit_area_type(area_changeset, ["quadrant", "site"])
  end
  defp validate_limit_area_type(value, area_changeset, valid_list) do
    value
    |> Enum.uniq()
    |> Enum.with_index(1)
    |> Enum.map(fn({val, index}) ->
      %{value: val, index: index}
      |> validate_list_inclusion(area_changeset, valid_list)
    end)
    |> merge_changeset_errors(area_changeset)
  end

  defp validate_list_inclusion(data, area_changeset, valid_list) do
    valid_list
    |> Enum.member?(data.value)
    |> if_not_member(area_changeset, :limit_area_type, data)
  end

  defp if_not_member(true, area_changeset, limit_area_type, data), do: area_changeset
  defp if_not_member(false, area_changeset, limit_area_type, data) do
    area_changeset
    |> Changeset.add_error(
      limit_area_type,
      "limit_area_type-index#{data.index} #{data.value} is invalid, You can only set ['Quadrant', 'Site']"
    )
  end

  defp is_site_selected?(area_changeset, data) do
    with true <- area_changeset.valid?,
         true <- Map.has_key?(area_changeset.changes, :limit_area_type),
         false <- area_changeset.changes.limit_area_type |> Enum.empty?(),
         false <- [""] == area_changeset.changes.limit_area_type
    do
      area_changeset.changes.limit_area_type
      |> Enum.map(fn(x) -> String.downcase(x) end)
      |> Enum.sort()
      |> Enum.member?("site")
      |> is_site_selected?(area_changeset, data)
    else
      false ->
        area_changeset
      true ->
        area_changeset |> Changeset.add_error(:limit_area_type, "At least one of the following is required. Enter ['Quadrant', 'Site']")
      _ ->
        area_changeset
    end
  end

  defp is_site_selected?(false, area_changeset, data) do
    if Map.has_key?(area_changeset.changes, :limit_area) do
      Changeset.add_error(area_changeset, :limit_area, "is not belongs to the valid parameters")
    else
      area_changeset
    end
  end
  defp is_site_selected?(true, %{changes: %{limit_area: [""]}} = area_changeset, data) do
    area_changeset |> Changeset.add_error(
      :limit_area_type,
      "At least one of the following is required: ['Upper inner lip', 'Lower inner lip', 'Cheek area', 'Palatal area', 'Tongue', 'Floor of the mouth']"
    )
  end
  defp is_site_selected?(true, %{changes: %{limit_area: []}} = area_changeset, data) do
    area_changeset |> Changeset.add_error(
      :limit_area_type,
      "At least one of the following is required: ['Upper inner lip', 'Lower inner lip', 'Cheek area', 'Palatal area', 'Tongue', 'Floor of the mouth']"
    )
  end
  defp is_site_selected?(true, area_changeset, data) do
    area_changeset
    |> Changeset.validate_required([
      :limit_area
    ])
    |> validate_limit_area_array_value()
  end

  def validate_limit_area_array_value(area_changeset) do
    with true <- area_changeset.valid? do
      area_changeset.changes.limit_area
      |> Enum.with_index(1)
      |> Enum.map(fn({val, index}) ->
        ["Upper inner lip", "Lower inner lip", "Cheek area", "Palatal area", "Tongue", "Floor of the mouth"]
        |> Enum.map(&(&1
        |> String.downcase()))
        |> is_included?(
          %{value: val |> String.downcase(), index: index}, area_changeset
        )
      end)
      |> merge_changeset_errors(area_changeset)
    else
      false ->
        area_changeset
    end
  end
  def is_included?(limit_area_choices, data, area_changeset) do
    limit_area_choices
    |>  Enum.member?(data.value)
    |> valid_limit_area?(area_changeset, data)
  end

  def valid_limit_area?(true, area_changeset, data), do: area_changeset
  def valid_limit_area?(false, area_changeset, data) do
    area_changeset
    |> Changeset.add_error(
      "limit_area-index-#{data.index}",
      "#{data.value} is invalid, The following choices would be ['Upper inner lip', 'Lower inner lip', 'Cheek area', 'Palatal area', 'Tongue', 'Floor of the mouth']"
    )
  end
  ########### end: validation for area #######################################\\\\\
  #################################### end: validate_limits  #####################################

  def transform_data(changeset) do
    with true <- Map.has_key?(changeset.changes, :frequency)
    do
      changeset
      |> string_capitalize(changeset.changes.category, :category)
      |> string_capitalize(changeset.changes.type, :type)
      |> string_capitalize(changeset.changes.frequency, :frequency)
      |> transform_second_layer()
    else
      false ->
        changeset
        |> string_capitalize(changeset.changes.category, :category)
        |> string_capitalize(changeset.changes.type, :type)
        |> transform_second_layer()
    end
  end

  defp string_capitalize_frequency(%{changes: %{frequency: frequency}} = changeset) do
    changeset
    |> string_capitalize_frequency(changeset.changes.frequency, :frequency)
  end

  defp string_capitalize_frequency(changeset), do: changeset

  defp transform_second_layer(%{changes: %{limits: _limits}} = changeset) do
    limits =
      changeset.changes.limits
      |> Enum.into([], fn(limit_map) ->
        transform_checker(limit_map["limit_type"] |> String.downcase, limit_map)
      end)

    changeset
    |> Changeset.change(limits: limits)
  end

  defp transform_second_layer(changeset), do: changeset

  defp transform_checker("peso", limit_map), do: limit_map |> peso_transform()
  defp transform_checker("session", limit_map), do: limit_map |> session_transform()
  defp transform_checker("tooth", limit_map), do: limit_map |> tooth_transform()
  defp transform_checker("area", limit_map), do: limit_map |> area_transform()

  defp peso_transform(limit_map), do: limit_map |> Map.put("limit_type", String.capitalize(limit_map["limit_type"]))
  defp session_transform(limit_map), do: limit_map |> Map.put("limit_type", String.capitalize(limit_map["limit_type"]))
  defp tooth_transform(limit_map), do: limit_map |> Map.put("limit_type", String.capitalize(limit_map["limit_type"]))
  defp area_transform(limit_map) do
    if limit_map["limit_area_type"] |> Enum.map(&(&1 |> String.downcase())) |> Enum.member?("site") do
      limit_map
      |> Map.put("limit_area_type", capitalize_array_values(limit_map["limit_area_type"]))
      |> Map.put("limit_type", String.capitalize(limit_map["limit_type"]))
      |> Map.put("limit_area", capitalize_array_values(limit_map["limit_area"]))
    else
      limit_map
      |> Map.put("limit_area_type", capitalize_array_values(limit_map["limit_area_type"]))
      |> Map.put("limit_type", String.capitalize(limit_map["limit_type"]))
    end
  end

  defp string_capitalize(changeset, value, key), do: changeset |> Changeset.put_change(key, value |> String.capitalize())
  defp capitalize_array_values(array), do: array |> Enum.map(fn(n) -> String.capitalize(n) end)

  def insert_sap_benefit_dental(changeset, user) do
    map = %{created_by_id: user.id, updated_by_id: user.id}
    %Benefit{}
    |> Benefit.changeset_sap_dental(changeset.changes |> Map.merge(map))
    |> Repo.insert()
  end

  defp changeset_valid?(changeset), do: if changeset.valid?, do: {:ok, changeset}, else: {:error, changeset}
  defp merge_changeset_errors([head|tails], changeset), do: merge_changeset_errors(tails, Changeset.merge(changeset, head))
  defp merge_changeset_errors([], changeset), do: changeset

  defp insert_benefit_coverages(benefit_id, changeset) do
    with true <- Map.has_key?(changeset.changes, :coverages) do
      changeset.changes.coverages
      |> Enum.each(fn(k) -> k
        %BenefitCoverage{}
        |> BenefitCoverage.changeset(%{benefit_id: benefit_id, coverage_id: get_coverage_data_by_code(k).id})
        |> Repo.insert()
      end)
    else
      _ ->
        ["DENTL"]
        |> Enum.each(fn(k) -> k
          %BenefitCoverage{}
          |> BenefitCoverage.changeset(%{benefit_id: benefit_id, coverage_id: get_coverage_data_by_code(k).id})
          |> Repo.insert()
        end)
    end
  end

  defp insert_benefit_cdt(benefit_id, changeset) do
    with true <- Map.has_key?(changeset.changes, :cdt) do
      changeset.changes.cdt
      |> Enum.uniq()
      |> Enum.each(fn(cdt) ->
        %BenefitProcedure{}
        |> BenefitProcedure.changeset(%{benefit_id: benefit_id, procedure_id: get_procedure_by_code(cdt).id})
        |> Repo.insert()
      end)
    else
      _ ->
        :ok
    end
  end

  defp insert_benefit_limits(benefit_id, changeset) do
    with true <- Map.has_key?(changeset.changes, :limits) do
      changeset.changes.limits
      |> Enum.each(fn(u) -> u
        params = %{
          benefit_id: benefit_id,
          coverages: u["coverages"] |> Enum.join(", "),
          limit_type: u["limit_type"],
          limit_amount: u["limit_amount"],
          limit_session: u["limit_session"],
          limit_area_type: u["limit_area_type"],
          limit_area: u["limit_area"],
        }
        %BenefitLimit{}
        |> BenefitLimit.changeset_sap_dental(params)
        |> Repo.insert()
      end)
    else
      _ ->
        :ok
    end
  end

  defp get_procedure_by_code(code) do
    PayorProcedure
    |> where([pp], pp.code == ^code and pp.is_active == true)
    |> Repo.one()
  end

  defp get_coverage_data_by_code(code) do
    Coverage
    |> where([c], c.code == ^code)
    |> select([c], c)
    |> Repo.one()
  end

  defp preload_sap_dental(struct) do
    struct
    |> Repo.preload([
      :benefit_limits,
      benefit_procedures: :procedure,
      benefit_coverages: :coverage
    ])
  end

end
