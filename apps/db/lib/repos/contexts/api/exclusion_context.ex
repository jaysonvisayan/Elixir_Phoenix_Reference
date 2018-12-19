defmodule Innerpeace.Db.Base.Api.ExclusionContext do
  @moduledoc false

  alias Innerpeace.Db.{
    Repo,
    Base.Api.UtilityContext,
    Schemas.Exclusion,
    Schemas.ExclusionDisease,
    Schemas.ExclusionProcedure,
    Schemas.Diagnosis,
    Schemas.PayorProcedure,
    Schemas.ExclusionDuration,
    Schemas.ExclusionCondition,
    Schemas.User
  }
  alias Ecto.Changeset

  import Ecto.Query

  def search_all_exclusions do
    Exclusion
    |> Repo.all
    |> Repo.preload([exclusion_diseases: :disease, exclusion_procedures: :procedure])
  end

  def search_exclusion(params) do
    Exclusion
    |> where(
      [e],
      (
        is_nil(e.name)
        or ilike(
          fragment(
            "lower(?)",
            e.name
          ),
          fragment(
            "lower(?)",
            ^"%#{params["exclusion"]}%"
          )
        )
      )
      or (
        is_nil(e.code)
        or ilike(
          fragment(
            "lower(?)",
            e.code
          ),
          fragment(
            "lower(?)",
            ^"%#{params["exclusion"]}%"
          )
        )
      )
    )
    |> order_by([e], asc: e.inserted_at)
    |> preload([exclusion_diseases: :disease, exclusion_procedures: :procedure])
    |> Repo.all
  end

  def validate_custom_insert(user, params) do
    if is_nil(user) do
      {:unauthorized}
    else
      valid_coverages = ["general exclusion", "pre-existing condition"]

      with true <- not is_nil(params["coverage"]),
           true <- Enum.member?(valid_coverages, String.downcase(params["coverage"]))
      do
        case String.downcase(params["coverage"]) do
          "general exclusion" ->
            with {:ok, changeset} <- validate_ge_level1(params),
                 exclusion <- insert_ge(user, changeset)
            do
              {:ge, exclusion}
            end
          "pre-existing condition" ->
            with {:ok, changeset} <- validate_precon_level1(params),
                 exclusion <- insert_precon(user, changeset)
            do
              {:precon, exclusion}
            end
        end
      else
        _ ->
          {:invalid_coverage}
      end
    end
  end

  def validate_general_insert(user, params) do
    if is_nil(user) do
      {:unauthorized}
    else
      valid_coverages = ["general", "general exclusion", "pre-existing condition"]

      with {:ok, changeset} <- validate_genex_level1(params),
           exclusion <- insert_genex(user, changeset)
      do
        {:genex, exclusion}
      end
    end
  end

  defp validate_genex_level1(params) do
    data = %{}
    parameter_type = %{
      disease: {:array, :string},
      procedure: {:array, :string}
    }
    changeset =
      {data, parameter_type}
      |> Changeset.cast(params, Map.keys(parameter_type))
      |> Changeset.validate_required([
        :disease,
        :procedure
      ])

    if changeset.valid? do
      validate_genex_level2(changeset)
    else
      {:error, changeset}
    end
  end

  defp validate_genex_level2(changeset) do
    changeset =
      changeset
      |> validate_diseases
      |> validate_procedures

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp validate_diseases(changeset) do
    disease_list = changeset.changes[:disease]
    if disease_list != [] do
      result = [] ++ for dl <- disease_list do
        if get_disease(dl) == nil do
          if dl == "" do
            Changeset.add_error(changeset, :disease, "Empty strings are not accepted.")
          else
            Changeset.add_error(changeset, :disease, dl <> " does not exist.")
          end
        else
          disease = get_disease(dl)
          if not is_nil(disease.exclusion_type) do
            Changeset.add_error(changeset, :disease, dl <> " already has an exclusion type.")
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
      procedure_list = changeset.changes[:procedure]
      if procedure_list != [] do
        changeset
      else
        Changeset.add_error(changeset, :disease, "Please enter atleast one disease code.")
      end
    end
  end

  defp get_disease(code) do
    Diagnosis
    |> where([d], ilike(d.code, ^code))
    |> Repo.one
  end

  defp validate_procedures(changeset) do
    procedure_list = changeset.changes[:procedure]
    if procedure_list != [] do
      result = for pl <- procedure_list do
        if get_procedure(pl) == nil do
          if pl == "" do
            Changeset.add_error(changeset, :procedure, "Empty strings are not accepted.")
          else
            Changeset.add_error(changeset, :procedure, pl <> " does not exist.")
          end
        else
          procedure = get_procedure(pl)
          if not is_nil(procedure.exclusion_type) do
            Changeset.add_error(changeset, :procedure, pl <> " already has an exclusion type.")
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
      disease_list = changeset.changes[:disease]
      if disease_list != [] do
        changeset
      else
        Changeset.add_error(changeset, :procedure, "Please enter atleast one procedure code.")
      end
    end
  end

  defp get_procedure(code) do
    PayorProcedure
    |> where([p], ilike(p.code, ^code))
    |> Repo.one
  end

  defp merge_changeset_errors([head | tails], changeset) do
    prev_changeset = changeset
    new_changeset = head
    merge_changeset_errors(tails, Changeset.merge(prev_changeset, new_changeset))
  end

  defp merge_changeset_errors([], changeset), do: changeset

  defp insert_genex(_user, changeset) do
    disease_list = changeset.changes[:disease]
    disease_list = [] ++ for dl <- disease_list do
      disease = get_disease(dl)
      disease
      |> Diagnosis.changeset_exclusion_type(%{exclusion_type: "General Exclusion"})
      |> Repo.update!
    end

    procedure_list = changeset.changes[:procedure]
    procedure_list = [] ++ for pl <- procedure_list do
      procedure = get_procedure(pl)
      procedure
      |> PayorProcedure.changeset_exclusion_type(%{exclusion_type: "General Exclusion"})
      |> Repo.update!
    end

    %{
      disease: disease_list,
      procedure: procedure_list
    }
  end

  defp validate_precon_level1(params) do
    data = %{}
    parameter_type = %{
      coverage: :string,
      code: :string,
      name: :string,
      duration: {:array, :map},
      disease: {:array, :string}
    }
    changeset =
      {data, parameter_type}
      |> Changeset.cast(params, Map.keys(parameter_type))
      |> Changeset.validate_required([
        :coverage,
        :code,
        :name,
        :duration,
        :disease
      ])

    if changeset.valid? do
      validate_precon_level2(changeset)
    else
      {:error, changeset}
    end
  end

  defp validate_precon_level2(changeset) do
    changeset =
      changeset
      |> validate_code
      |> validate_duration

    if changeset.valid? do
      validate_precon_level3(changeset)
    else
      {:error, changeset}
    end
  end

  defp validate_precon_level3(changeset) do
    changeset =
      changeset
      |> validate_precon_diseases

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp validate_code(changeset) do
    code = changeset.changes[:code]
    exclusion =
      Exclusion
      |> where([e], ilike(e.code, ^code))
      |> Repo.one

    if is_nil(exclusion) do
      changeset
    else
      Changeset.add_error(changeset, :code, "Code is already in use.")
    end
  end

  defp validate_duration(changeset) do
    duration_list = changeset.changes[:duration]
    if duration_list == [] do
      Changeset.add_error(changeset, :duration, "Please enter atleast one duration.")
    else
      result = [] ++ for {dl, index} <- Enum.with_index(duration_list, 1) do

        with false <- Enum.empty?(dl),
             true <- dl["disease_type"] != "",
             true <- check_key(dl, "disease_type"),
             true <- dl["duration"] != "",
             true <- check_key(dl, "duration"),
             true <- dl["covered_after_duration"] != "",
             true <- check_key(dl, "covered_after_duration"),
             true <- dl["value"] != "",
             true <- check_key(dl, "value")
        do
          [
            check_disease_type(changeset, dl["disease_type"], index),
            check_duration(changeset, dl["duration"], index),
            check_cad(changeset, dl["covered_after_duration"], index),
            check_cad_value(changeset, dl["covered_after_duration"], dl["value"], index)
          ]
        else
          {:missing_key, message} ->
            Changeset.add_error(changeset, :"duration_row#{index}", message)

          _ ->
            Changeset.add_error(changeset, :"duration_row#{index}", "Please enter a key or value on each field.")
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

  defp check_key(params, key) do
    if Map.has_key?(params, key) do
      true
    else
      {:missing_key, "#{key} is missing."}
    end
  end

  defp check_disease_type(changeset, type, index) do
    valid_type = ["dreaded", "non-dreaded"]
    new_type = String.downcase(type)
    if Enum.member?(valid_type, new_type) do
      nil
    else
      Changeset.add_error(changeset, :"duration_row#{index}", type <> " is invalid. Please enter if the disease is Dreaded or Non-Dreaded.")
    end
  end

  defp check_duration(changeset, duration, index) do
    if validate_numbers(duration) do
      nil
    else
      Changeset.add_error(changeset, :"duration_row#{index}", duration <> " is invalid. Please enter a valid duration.")
    end
  end

  defp check_percentage(changeset, percentage, index) do
    if validate_numbers(percentage) do
      if String.to_integer(percentage) <= 100 and String.to_integer(percentage) > 0 do
        nil
      else
        Changeset.add_error(changeset, :"duration_row#{index}", percentage <> " is invalid. Please enter a value from 1 to 100 only.")
      end
    else
      Changeset.add_error(changeset, :"duration_row#{index}", percentage <> " is invalid. Please enter a valid percentage.")
    end
  end

  defp check_cad(changeset, covered_after_duration, index) do
    valid_type = ["peso", "percentage"]
    cad_type = String.downcase(covered_after_duration)
    if Enum.member?(valid_type, cad_type) do
      nil

    else
      Changeset.add_error(changeset, :"duration_row#{index}", covered_after_duration <> " is invalid. Please enter if the covered after duration is Peso or Percentage.")
    end
  end

  defp check_cad_value(changeset, covered_after_duration, value, index) do
    lowered_cad = String.downcase(covered_after_duration)
    case lowered_cad do

      "peso" ->
        if validate_decimal(value) do
          if Decimal.new(value) > Decimal.new(0) do
            nil
          else
            Changeset.add_error(changeset, :"duration_row#{index}", value <> " is invalid. Value must be greater than 1.")
          end
        else
          Changeset.add_error(changeset, :"duration_row#{index}", value <> " is invalid. Please enter a valid amount.")
        end

      "percentage" ->
        if validate_numbers(value) do
          if String.to_integer(value) <= 100 and String.to_integer(value) > 0 do
            ### correct!
            nil
          else
            Changeset.add_error(changeset, :"duration_row#{index}", value <> " is invalid. Please enter a value from 1 to 100 only.")
          end
        else
          Changeset.add_error(changeset, :"duration_row#{index}", value <> " is invalid. Please enter a valid percentage.")
        end

      _ ->
        Changeset.add_error(changeset, :"duration_row#{index}", value <> " is invalid. Please enter a valid value.")

    end

  end

  defp validate_numbers(string) do
    Regex.match?(~r/^[0-9]*$/, string)
  end

  defp validate_decimal(string) do
    Regex.match?(~r/^[0-9]*(\.[0-9]{1,2})?$/, string)
  end

  defp validate_precon_diseases(changeset) do
    disease_list = changeset.changes[:disease]
    if disease_list != [] do
      result = [] ++ for dl <- disease_list do
        if dl == "" do
          Changeset.add_error(changeset, :disease, "Empty strings are not accepted.")
        else
          disease = get_disease(dl)
          if is_nil(disease) do
            Changeset.add_error(changeset, :disease, dl <> " does not exist.")
          else
            if disease.exclusion_type != "Pre-existing condition" do
              Changeset.add_error(changeset, :disease, dl <> "'s exclusion type is not Pre-existing condition.'")
            else
              durations = [] ++ for d <- changeset.changes[:duration] do
                String.downcase(d["disease_type"])
              end
              durations =
                durations
                |> Enum.uniq

              disease_type = String.downcase(disease.type)

              error_msg = Enum.join(durations, " or ")
              if Enum.member?(durations, disease_type) do
                changeset
              else
                Changeset.add_error(changeset, :disease, dl <> "'s diagnosis type is #{disease_type} which is not allowed. Please enter a #{error_msg} disease.")
              end
            end
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
      Changeset.add_error(changeset, :disease, "Please enter atleast one disease code.")
    end
  end

  defp insert_precon(user, changeset) do
    params = %{
      code: changeset.changes[:code],
      coverage: changeset.changes[:coverage],
      name: changeset.changes[:name],
      created_by_id: user.id,
      updated_by_id: user.id
    }

    exclusion =
      %Exclusion{}
      |> Exclusion.changeset_pre_existing(params)
      |> Repo.insert!

    exclusion
    |> Exclusion.changeset_step(%{step: "0", updated_by_id: user.id})
    |> Repo.update()

    duration_param_list = changeset.changes[:duration]
    _duration_list = [] ++ for dpl <- duration_param_list do

      case String.downcase(dpl["covered_after_duration"]) do

        "peso" ->
         duration_params = Map.merge(dpl, %{"exclusion_id" => exclusion.id, "cad_amount" => dpl["value"]})

        "percentage" ->
          duration_params = Map.merge(dpl, %{"exclusion_id" => exclusion.id, "cad_percentage" => dpl["value"]})

      end

      %ExclusionDuration{}
      |> ExclusionDuration.changeset(duration_params)
      |> Repo.insert!
    end

    disease_param_list = changeset.changes[:disease]
    _disease_list = [] ++ for dl <- disease_param_list do
      disease = get_disease(dl)
      dl_params = %{
        exclusion_id: exclusion.id,
        disease_id: disease.id
      }

      %ExclusionDisease{}
      |> ExclusionDisease.changeset(dl_params)
      |> Repo.insert!
    end

    Exclusion
    |> where([e], e.id == ^exclusion.id)
    |> Repo.one
    |> Repo.preload([:exclusion_durations, exclusion_diseases: [:disease]])
  end

  defp validate_ge_level1(params) do
    data = %{}
    parameter_type = %{
      coverage: :string,
      code: :string,
      name: :string,
      procedure: {:array, :string},
      disease: {:array, :string}
    }
    changeset =
      {data, parameter_type}
      |> Changeset.cast(params, Map.keys(parameter_type))
      |> Changeset.validate_required([
        :coverage,
        :code,
        :name,
        :procedure,
        :disease
      ])

    if changeset.valid? do
      validate_ge_level2(changeset)
    else
      {:error, changeset}
    end
  end

  defp validate_ge_level2(changeset) do
    changeset =
      changeset
      |> validate_code
      |> validate_ge_procedure
      |> validate_ge_disease

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  # Duplicate function
  # defp get_procedure(code) do
  #   PayorProcedure
  #   |> where([p], ilike(p.code, ^code))
  #   |> Repo.one
  # end

  defp validate_ge_procedure(changeset) do
    procedure_list = changeset.changes[:procedure]

    if procedure_list != [] do
      result = [] ++ for pl <- procedure_list do
        if pl == "" do
          Changeset.add_error(changeset, :procedure, "Empty strings are not accepted.")
        else
          procedure = get_procedure(pl)
          if is_nil(procedure) do
            Changeset.add_error(changeset, :procedure, pl <> " does not exist.")
          else
            if procedure.exclusion_type != "General Exclusion" do
              Changeset.add_error(changeset, :procedure, pl <> "'s exclusion type is not General Exclusion.'")
            else
              nil
            end
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
      disease_list = changeset.changes[:disease]
      if disease_list != [] do
        changeset
      else
        Changeset.add_error(changeset, :procedure, "Please enter atleast one disease code.")
      end
    end
  end

  defp validate_ge_disease(changeset) do
    disease_list = changeset.changes[:disease]

    if disease_list != [] do
      result = [] ++ for dl <- disease_list do
        if dl == "" do
          Changeset.add_error(changeset, :disease, "Empty strings are not accepted.")
        else
          disease = get_disease(dl)
          if is_nil(disease) do
            Changeset.add_error(changeset, :disease, dl <> " does not exist.")
          else
            if disease.exclusion_type != "General Exclusion" do
              Changeset.add_error(changeset, :disease, dl <> "'s exclusion type is not General Exclusion.'")
            else
              nil
            end
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
      procedure_list = changeset.changes[:procedure]
      if procedure_list != [] do
        changeset
      else
        Changeset.add_error(changeset, :disease, "Please enter atleast one disease code.")
      end
    end
  end

  defp insert_ge(user, changeset) do
    params = %{
      code: changeset.changes[:code],
      coverage: changeset.changes[:coverage],
      name: changeset.changes[:name],
      created_by_id: user.id,
      updated_by_id: user.id
    }

    exclusion =
      %Exclusion{}
      |> Exclusion.changeset_exclusion(params)
      |> Repo.insert!

    exclusion
    |> Exclusion.changeset_step(%{step: "0", updated_by_id: user.id})
    |> Repo.update()

    disease_param_list = changeset.changes[:disease]
    _disease_list = [] ++ for dl <- disease_param_list do
      disease = get_disease(dl)
      dl_params = %{
        exclusion_id: exclusion.id,
        disease_id: disease.id
      }

      %ExclusionDisease{}
      |> ExclusionDisease.changeset(dl_params)
      |> Repo.insert!
    end

    procedure_param_list = changeset.changes[:procedure]
    _procedure_list = [] ++ for pl <- procedure_param_list do
      procedure = get_procedure(pl)
      pl_params = %{
        exclusion_id: exclusion.id,
        procedure_id: procedure.id
      }

      %ExclusionProcedure{}
      |> ExclusionProcedure.changeset(pl_params)
      |> Repo.insert!
    end

    Exclusion
    |> where([e], e.id == ^exclusion.id)
    |> Repo.one
    |> Repo.preload([exclusion_procedures: [:procedure], exclusion_diseases: [:disease]])
  end

  def get_exclusion_by_id(id) do
    Exclusion
    |> Repo.get(id)
    |> Repo.preload(
      [
        :created_by,
        :updated_by,
        :exclusion_durations,
        exclusion_diseases: :disease,
        exclusion_procedures: [procedure: [:procedure_logs, [procedure: :procedure_category]]]
      ])
  end

  def get_exclusion_by_code_or_name(code, nil) do
      Exclusion
      |> where([e], e.code == ^code or e.name == ^code)
      |> preload([
          :updated_by,
          :exclusion_conditions,
          [exclusion_diseases: :disease]
         ])
      |> Repo.all()
      |> check_multiple_results()
    
  end

  defp check_multiple_results(exclusion) do
    if not Enum.empty?(exclusion) do
      with true <- Enum.count(exclusion) > 1 do
        {:error, "Expected at most one result but got many"}
      else
        _ -> 
        false
          {:ok, List.first(exclusion)}
      end
    else
      {:error, "Pre Existing not found."}
    end
  end

  def get_exclusion_by_code_or_name(code, _) do
    exclusion =
      Exclusion
      |> where([e], e.code == ^code or e.name == ^code)
      |> preload([:updated_by])
      |> Repo.all()
      |> check_multiple_results() 
      #if not is_nil(exclusion), do: exclusion |> Map.put(:exclusion_conditions, []) |> Map.put(:exclusion_diseases, [])
  end

  def create_pre_existing(params, user) do
    with {:ok, changeset} <- validate_pre_existing(params),
         {:ok, exclusion} <- insert_pre_existing(changeset, user),
         {:ok, conditions} <- validate_conditions_optional(exclusion, changeset),
         {:ok, diagnoses} <- insert_diagnoses(exclusion, changeset.changes.diagnosis_ids)
    do 

     
      exclusion =
        exclusion
        |> Map.put(:conditions, conditions)
        |> Map.put(:diagnoses, diagnoses)
      {:ok, exclusion}
    else
      {:error, changeset} ->
        {:error, changeset}
      _ ->
        {:invalid}
    end
  end

  defp validate_pre_existing(params) do
    fields = %{
      code: :string,
      name: :string,
      diagnosis: {:array, :string},
      applicability: {:array, :string},
      conditions: {:array, :map}
    }
    changeset =
      {%{}, fields}
      |> Changeset.cast(params, Map.keys(fields))
      |> Changeset.validate_required([:code], message: "Enter code")
      |> Changeset.validate_required([:name], message: "Enter name")
      |> Changeset.validate_required([:diagnosis], message: "Add at least one diagnosis")
      |> Changeset.validate_format(:code, ~r/^[a-zA-Z0-9_.-]*$/, message: "Pre-existing condition code only accepts (-) hypen, (.) dot, (_) underscore")
      |> Changeset.validate_length(:code, max: 50, message: "Pre-existing condition code only accepts 50 alphanumeric characters")
      |> Changeset.validate_length(:name, max: 80, message: "Pre-existing condition name only accepts 80 alphanumeric characters")
      |> put_fixed_values()
      #|> validate_applicability()
      |> validate_exclusion_code()
      |> validate_diagnosis_codes()
      |> validate_conditions()
      # |> validate_conditions_within()
      # |> validate_conditions_outside()
    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp put_fixed_values(changeset) do
    changeset
    |> Changeset.put_change(:applicability, ["Principal", "Dependent"])
  end

  defp validate_conditions_optional(exclusion, changeset) do
    with true <- Map.has_key?(changeset.changes, :conditions) do
       insert_conditions(exclusion, changeset.changes.conditions)
    else
      _ ->
        {:ok, changeset.changes}
    end
  end

  defp validate_applicability(changeset) do
    with true <- Map.has_key?(changeset.changes, :applicability),
         applicability <- changeset.changes.applicability
    do
      applicability = Enum.map(applicability, &String.capitalize/1)
      changeset =
        changeset
        |> Changeset.put_change(:applicability, applicability)
        |> Changeset.validate_subset(:applicability, ["Principal", "Dependent"], message: "is invalid")
      if changeset.valid? do
        changeset
      else
        Changeset.delete_change(changeset, :applicability)
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_conditions_within(changeset) do
    with true <- Map.has_key?(changeset.changes, :conditions) do
      count =
        changeset.changes.conditions
        |> Enum.filter(&(Map.has_key?(&1, "within_grace_period")))
        |> Enum.filter(&(
          &1["within_grace_period"] == true or
          &1["within_grace_period"] == "true"
        ))
        |> Enum.count()
      if count > 0 do
        changeset
      else
        Changeset.add_error(changeset, :conditions, "At least one within grace period is required")
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_conditions_outside(changeset) do
    with true <- Map.has_key?(changeset.changes, :conditions) do
      count =
        changeset.changes.conditions
        |> Enum.filter(&(Map.has_key?(&1, "within_grace_period")))
        |> Enum.filter(&(
          &1["within_grace_period"] == false or
          &1["within_grace_period"] == "false"
        ))
        |> Enum.count()
      if count > 0 do
        changeset
      else
        Changeset.add_error(changeset, :conditions, "At least one outside grace period is required")
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_conditions(changeset) do
    with true <- Map.has_key?(changeset.changes, :conditions),
         true <- Map.has_key?(changeset.changes, :applicability),
         false <- Enum.empty?(changeset.changes.applicability)
    do
      applicability = changeset.changes.applicability
      
      errors =
      changeset.changes.conditions
      |> Enum.with_index(1)
      |> validate_condition_params([], applicability)
      if Enum.empty?(errors) do
        changeset
      else
        Changeset.add_error(changeset, :conditions, Enum.join(errors, ", "))
      end

    else
      _ ->
        changeset
    end
  end

  defp validate_condition_params([{params, index} | tails], errors, applicability) do
    fields = %{
      member_type: :string,
      diagnosis_type: :string,
      duration: :integer,
      limit_type: :string,
      limit_amount: :string
    }
    changeset =
      {%{}, fields}
      |> Changeset.cast(params, Map.keys(fields))
      |> Changeset.validate_required([:member_type], message: "Enter member type")
      |> Changeset.validate_required([:diagnosis_type], message: "Enter diagnosis type")
      |> Changeset.validate_required([:duration], message: "Enter duration")
      |> Changeset.validate_required([:limit_type], message: "Enter limit type")
      |> Changeset.validate_required([:limit_amount], message: "Enter limit amount")
      |> capitalize_member_type()
      |> capitalize_diagnosis_type()
      |> capitalize_limit_type() 
      |> Changeset.validate_inclusion(:member_type, ["Principal", "Dependent"], message: "Enter member type: Principal or Dependent")
      |> Changeset.validate_inclusion(:limit_type, ["Peso", "Percentage"], message: "Enter limit type: Peso or Percentage")
      |> Changeset.validate_inclusion(:diagnosis_type, ["Dreaded", "Non-dreaded"], message: "Enter diagnosis: Dreaded or Non-Dreaded")
      |> Changeset.validate_number(:duration, greater_than: -1, less_than: 10000, message: "Duration only allows maximum of 4 characters")
      |> validate_limit_amount()

     if changeset.valid? do
       validate_condition_params(tails, errors, applicability)
     else
      changeset_errors = UtilityContext.changeset_errors_to_string2(changeset.errors)
      errors = errors ++ ["Row #{index} errors: (#{changeset_errors})"]
      validate_condition_params(tails, errors, applicability)
    end
  end

  defp validate_condition_params([], errors, applicability), do: errors

  defp capitalize_member_type(%{
    changes: %{
      member_type: member_type
    }
  } = changeset) do
    member_type = String.capitalize(member_type)
    Changeset.put_change(changeset, :member_type, member_type)
  end

  defp capitalize_member_type(changeset), do: changeset

  defp capitalize_diagnosis_type(%{
    changes: %{
      diagnosis_type: type
    }
  } = changeset) do
    type = String.capitalize(type)
    Changeset.put_change(changeset, :diagnosis_type, type)
  end

  defp capitalize_diagnosis_type(changeset), do: changeset

  defp capitalize_limit_type(%{
    changes: %{
      limit_type: type
    }
  } = changeset) do
    type = String.capitalize(type)
    Changeset.put_change(changeset, :limit_type, type)
  end

  defp capitalize_limit_type(changeset), do: changeset

  defp validate_limit_amount(%{
    changes: %{
      limit_type: "Percentage",
      limit_amount: limit_amount
    }
  } = changeset) do
    if Enum.member?(generate_string_list(), limit_amount) do
      changeset
    else
      Changeset.add_error(changeset, :limit_amount, "Percentage only allows minimum of 1% and maximum of 100%")
    end
  end

  defp generate_string_list do
    for x <- 1..100, do: Integer.to_string(x)
  end

  defp validate_limit_amount(%{
    changes: %{
      limit_type: "Peso",
      limit_amount: limit_amount
    }
  } = changeset) do
    changeset
    |> Changeset.validate_format(:limit_amount, ~r/^[0-9]*(\.[0-9]{1,90})?$/, message: "Special characters are not allowed")
    |> validate_peso_limit()
  end

  defp validate_peso_limit(changeset) do
    if changeset.changes.limit_amount > "1" && changeset.changes.limit_amount < "1000000" do
      changeset
    else
      Changeset.add_error(changeset, :limit_amount, "Limit amount only allows maximum of 6 characters.")
    end
  end

  defp validate_limit_amount(changeset), do: changeset

  defp validate_exclusion_code(changeset) do
    with true <- Map.has_key?(changeset.changes, :code) do
      if get_exclusion_by_code(changeset.changes.code) do
        Changeset.add_error(changeset, :code, "Code is already taken.")
      else
        changeset
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_diagnosis_codes(changeset) do
    with true <- Map.has_key?(changeset.changes, :diagnosis) do
      result = check_diagnosis_codes(changeset.changes.diagnosis)
      codes = Enum.map(result, fn({code, id}) -> code end)
      ids = Enum.map(result, fn({code, id}) -> id end)
      invalid_codes = Enum.uniq(changeset.changes.diagnosis) -- codes
      if Enum.empty?(invalid_codes) do
        Changeset.put_change(changeset, :diagnosis_ids, ids)
      else
        errors = Enum.join(invalid_codes, ", ")
        Changeset.add_error(changeset, :diagnosis, "Diagnosis not found")
      end
    else
      _ ->
        changeset
    end
  end

  defp check_invalid_diagnosis_codes(["" | tails], errors, diagnosis_ids) do
    if Enum.member?(errors, "empty strings are not allowed") do
      check_invalid_diagnosis_codes(tails, errors, diagnosis_ids)
    else
      error = errors ++ ["empty strings are not allowed"]
      check_invalid_diagnosis_codes(tails, error, diagnosis_ids)
    end
  end

  defp check_invalid_diagnosis_codes([head | tails], errors, diagnosis_ids) do
    diagnosis = get_diagnosis_by_code(head)
    if diagnosis do
      diagnosis_ids = diagnosis_ids ++ [diagnosis.id]
      check_invalid_diagnosis_codes(tails, errors, diagnosis_ids)
    else
      error = errors ++ ["#{head} does not exist"]
      check_invalid_diagnosis_codes(tails, error, diagnosis_ids)
    end
  end

  defp check_invalid_diagnosis_codes([], errors, diagnosis_ids), do: {errors, diagnosis_ids}

  defp check_diagnosis_codes(codes) do
    Diagnosis
    |> where([d], d.code in ^codes)
    |> select([d], {d.code, d.id})
    |> Repo.all()
  end

  defp get_diagnosis_by_code(code) do
    Diagnosis
    |> where([d], d.code == ^code)
    |> Repo.one()
  end

  def get_exclusion_by_code(code) do
    Exclusion
    |> where([e], e.code == ^code)
    |> Repo.one()
  end

  defp insert_pre_existing(changeset, user) do
    params = setup_prex_params(changeset, user)
    %Exclusion{}
    |> Exclusion.changeset_pre_ex_api(params)
    |> Repo.insert()
  end

  defp setup_prex_params(changeset, user) do
    applicability = changeset.changes.applicability
    dependent = Enum.member?(applicability, "Dependent")
    principal = Enum.member?(applicability, "Principal")
    %{
      code: changeset.changes.code,
      name: changeset.changes.name,
      is_applicability_dependent: dependent,
      is_applicability_principal: principal,
      created_by_id: user.id,
      updated_by_id: user.id,
      step: 0,
      coverage: "Pre-existing Condition"
    }
  end

  def insert_conditions(exclusion, conditions) do
    {:ok, Enum.map(conditions, fn(condition) ->
      params = %{
        member_type: condition["member_type"],
        diagnosis_type: condition["diagnosis_type"],
        duration: condition["duration"],
        inner_limit: condition["limit_type"],
        inner_limit_amount: condition["limit_amount"],
        within_grace_period: condition["within_grace_period"],
        exclusion_id: exclusion.id
      }
      %ExclusionCondition{}
      |> ExclusionCondition.changeset_api(params)
      |> Repo.insert!()
    end)}
  end

  def insert_diagnoses(exclusion, diagnoses) do
    {:ok, Enum.map(diagnoses, fn(diagnosis) ->
      params = %{
        exclusion_id: exclusion.id,
        disease_id: diagnosis
      }
      %ExclusionDisease{}
      |> ExclusionDisease.changeset(params)
      |> Repo.insert!()
      |> Repo.preload([:disease])
    end)}
  end

  def create_exclusion(params, user) do
    with {:ok, changeset} <- validate_exclusion(params),
         {:ok, exclusion} <- insert_exclusion(changeset, user),
         {:ok, diagnoses} <- insert_diagnoses(exclusion, changeset.changes.diagnosis_ids),
         {:ok, procedures} <- insert_procedures(exclusion, changeset.changes.procedure_ids)
    do
      exclusion =
        exclusion
        |> Map.put(:procedures, procedures)
        |> Map.put(:diagnoses, diagnoses)
      {:ok, exclusion}
    else
      {:error, changeset} ->
        {:error, changeset}
      _ ->
        {:invalid}
    end
  end

  defp validate_exclusion(params) do
    fields = %{
      code: :string,
      name: :string,
      type: :string,
      policy: {:array, :string},
      classification_type: :string,
      diagnoses: {:array, :string},
      procedures: {:array, :string}
    }
    changeset =
      {%{}, fields}
      |> Changeset.cast(params, Map.keys(fields))
      |> Changeset.validate_required([
        :code,
        :name,
        :type,
        :classification_type
      ])
      |> validate_exclusion_code()
      |> capitalize_classification_type()
      |> check_exclusion_type()
      |> validate_diagnosis_codes_exclusion()
      |> validate_procedure_codes()
      |> Changeset.validate_length(:code, max: 80)
      |> Changeset.validate_format(:code, ~r/^[a-zA-Z0-9_.-]*$/, message: "has invalid format")
      |> Changeset.validate_inclusion(:type, ["ICD/CPT Based", "Policy"], message: "ICD/CPT Based or Policy only")
      |> Changeset.validate_inclusion(:classification_type, ["Standard", "Custom"], message: "Standard or Custom only")

      if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp check_exclusion_type(changeset) do
    with true <- Map.has_key?(changeset.changes, :type) do
      if changeset.changes.type == "Policy" do
        changeset
        |> Changeset.validate_required([
          :policy
        ])
        |> Changeset.put_change(:diagnosis_ids, [])
        |> Changeset.put_change(:procedure_ids, [])
        |> Changeset.delete_change(:diagnoses)
        |> Changeset.delete_change(:procedures)
        |> Changeset.validate_length(:policy, min: 1, message: "at least one is required")
        |> validate_policy()
      else
        changeset
        |> Changeset.validate_required([
          :diagnoses,
          :procedures
        ])
        |> Changeset.validate_length(:diagnoses, min: 1, message: "at least one is required")
        |> Changeset.validate_length(:procedures, min: 1, message: "at least one is required")
        |> Changeset.delete_change(:policy)
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_policy(%{
    changes: %{
      policy: policy
    }
  } = changeset) do
    checker =
      policy
      |> Enum.with_index(1)
      |> Enum.map(fn({value, index}) ->
        if String.length(value) > 2000 do
          index
        else
          true
        end
      end)
    if Enum.all?(checker, &(&1 == true)) do
      changeset
    else
      checker =
        checker
        |> Enum.uniq()
        |> List.delete(true)
      Changeset.add_error(changeset, :policy, "rows #{Enum.join(checker, ", ")} exceeds 2000 limit")
    end
  end

  defp validate_policy(changeset), do: changeset

  defp capitalize_type(%{
    changes: %{
      type: type
    }
  } = changeset) do
    type = String.capitalize(type)
    Changeset.put_change(changeset, :type, type)
  end

  defp capitalize_type(changeset), do: changeset

  defp capitalize_classification_type(%{
    changes: %{
      classification_type: classification_type
    }
  } = changeset) do
    classification_type = String.capitalize(classification_type)
    Changeset.put_change(changeset, :classification_type, classification_type)
  end

  defp capitalize_classification_type(changeset), do: changeset

  defp validate_diagnosis_codes_exclusion(%{
    changes: %{
      type: "ICD/CPT Based",
      diagnoses: diagnoses
    }
  } = changeset) do
    result = check_diagnosis_codes(diagnoses)
    codes = Enum.map(result, fn({code, id}) -> code end)
    ids = Enum.map(result, fn({code, id}) -> id end)
    invalid_codes = Enum.uniq(diagnoses) -- codes
    if Enum.empty?(invalid_codes) do
      Changeset.put_change(changeset, :diagnosis_ids, ids)
    else
      errors = Enum.join(invalid_codes, ", ")
      Changeset.add_error(changeset, :diagnosis, "#{errors} does not exist")
    end
  end

  defp validate_diagnosis_codes_exclusion(changeset), do: changeset

  defp insert_exclusion(changeset, user) do
    params = setup_exclusion_params(changeset, user)
    %Exclusion{}
    |> Exclusion.changeset_exclusion_api(params)
    |> Repo.insert()
  end

  defp setup_exclusion_params(%{changes: %{policy: _policy}} = changeset, user) do
    %{
      code: changeset.changes.code,
      name: changeset.changes.name,
      type: changeset.changes.type,
      classification_type: changeset.changes.classification_type,
      policy: changeset.changes.policy,
      created_by_id: user.id,
      updated_by_id: user.id,
      step: 0,
      coverage: "Exclusion"
    }
  end

  defp setup_exclusion_params(changeset, user) do
    %{
      code: changeset.changes.code,
      name: changeset.changes.name,
      type: changeset.changes.type,
      classification_type: changeset.changes.classification_type,
      created_by_id: user.id,
      updated_by_id: user.id,
      step: 0,
      coverage: "Exclusion"
    }
  end

  defp validate_procedure_codes(%{
    changes: %{
      type: "ICD/CPT Based",
      procedures: procedures
    }
  } = changeset) do
    result = check_procedure_codes(procedures)
    codes = Enum.map(result, fn({code, id}) -> code end)
    ids = Enum.map(result, fn({code, id}) -> id end)
    invalid_codes = Enum.uniq(procedures) -- codes
    if Enum.empty?(invalid_codes) do
      Changeset.put_change(changeset, :procedure_ids, ids)
    else
      errors = Enum.join(invalid_codes, ", ")
      Changeset.add_error(changeset, :procedures, "#{errors} does not exist")
    end
  end

  defp validate_procedure_codes(changeset), do: changeset

  defp check_procedure_codes(codes) do
    PayorProcedure
    |> where([d], d.code in ^codes)
    |> select([d], {d.code, d.id})
    |> Repo.all()
  end

  def insert_procedures(exclusion, procedures) do
    {:ok, Enum.map(procedures, fn(procedure) ->
      params = %{
        exclusion_id: exclusion.id,
        procedure_id: procedure
      }
      %ExclusionProcedure{}
      |> ExclusionProcedure.changeset(params)
      |> Repo.insert!()
      |> Repo.preload([:procedure])
    end)}
  end

  def get_exclusion_by_code_sap(code) do
    Exclusion
    |> join(:inner, [e], u in User, e.updated_by_id == u.id)
    |> select([e, u], %{
      id: e.id,
      code: e.code,
      name: e.name,
      type: e.type,
      policy: e.policy,
      classification_type: e.classification_type,
      last_update: e.updated_at,
      last_updated_by: fragment("CONCAT(?, '  ', ?)", u.first_name, u.last_name)
    })
    |> where([e], e.code == ^code and e.coverage == "Exclusion")
    |> Repo.one()
    |> get_exclusion_details()
  end

  def get_exclusion_details(nil), do: nil

  def get_exclusion_details(exclusion) do
    exclusion
    |> Map.put(:diagnoses, get_exclusion_diagnoses(exclusion.id))
    |> Map.put(:procedures, get_exclusion_procedures(exclusion.id))
  end

  def get_exclusion_diagnoses(exclusion_id) do
    ExclusionDisease
    |> join(:inner, [ed], d in Diagnosis, ed.disease_id == d.id)
    |> where([ed], ed.exclusion_id == ^exclusion_id)
    |> Repo.all()
    |> Repo.preload([:disease])
  end

  def get_exclusion_procedures(exclusion_id) do
    ExclusionProcedure
    |> join(:inner, [ep], p in PayorProcedure, ep.procedure_id == p.id)
    |> where([ep], ep.exclusion_id == ^exclusion_id)
    |> Repo.all()
    |> Repo.preload([:procedure])
  end

end

