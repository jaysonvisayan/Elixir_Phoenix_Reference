defmodule Innerpeace.Db.Base.Api.ProcedureContext do
  @moduledoc false

  import Ecto.{Query}, warn: false
  alias Innerpeace.Db.{
    Repo,
    Schemas.PayorProcedure,
    Schemas.Procedure,
    Schemas.Payor,
  }

  alias Innerpeace.Db.Base.Api.{
    UtilityContext,
  }
  alias Ecto.Changeset

  def get_all_queried_payor_procedures(search_query) do
    query = "%#{search_query}%"
    pp_query = (
      from p in PayorProcedure,
      where: p.is_active == true
        and (ilike(p.description, ^query)
        or ilike(p.code, ^query)),
      select: p
    )

    pp_query
    |> Repo.all
    |> Repo.preload([
      :package_payor_procedures,
      :payor,
      :procedure_logs,
      procedure: :procedure_category,
      facility_payor_procedures: [facility: [:category, :type]]
    ])
  end

  def create(params) do
    with {:ok, changeset} <- validate_procedure_fields(params),
         {:ok, payor_procedure} <- insert_payor_procedure(changeset.changes),
         %PayorProcedure{} = payor_procedure <- get_payor_procedure!(payor_procedure.id)
    do
      {:ok, payor_procedure}
    else
      {:changeset_error, changeset} ->
        {:error, UtilityContext.changeset_errors_to_string(changeset.errors)}
      _ ->
        {:error, "Not found"}
    end
  end

  def insert_payor_procedure(params) do
    payor = Repo.get_by!(Payor, name: "Maxicare")
    params =
      params
      |> Map.put(:payor_id, payor.id)

    %PayorProcedure{}
    |> PayorProcedure.changeset(params)
    |> Repo.insert()
  end

  def validate_procedure_fields(params) do
    types = %{
      standard_cpt_code: :string,
      code: :string,
      description: :string
    }
    changeset =
      {%{}, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([
        :standard_cpt_code,
        :code,
        :description
      ], message: "is required")
      |> Changeset.validate_exclusion(:code, get_all_pp_codes(), message: "is already taken")
      |> validate_std_code()
    if changeset.valid? do
      {:ok, changeset}
    else
      {:changeset_error, changeset}
    end
  end

  def validate_general_exclusion(changeset) do
    with true <- Map.has_key?(changeset.changes, :general_exclusion) do
      case changeset.changes.general_exclusion do
        true ->
          Changeset.put_change(changeset, :exclusion_type, "General Exclusion")
        false ->
          Changeset.put_change(changeset, :exclusion_type, "N/A")
        _ ->
          Changeset.add_error(changeset, :exclusion_type, "is invalid")
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_std_code(changeset) do
    with true <- Map.has_key?(changeset.changes, :standard_cpt_code) do
      if std_procedure = get_std_by_code(changeset.changes.standard_cpt_code) do
        if Enum.empty?(get_active_std(std_procedure.id)) do
          Changeset.put_change(changeset, :procedure_id, std_procedure.id)
        else
          Changeset.add_error(changeset, :standard_cpt_code, "is already mapped")
        end
      else
        Changeset.add_error(changeset, :standard_cpt_code, "is invalid")
      end
    else
      _ ->
        changeset
    end
  end

  defp get_active_std(procedure_id) do
    PayorProcedure
    |> where([pp], pp.procedure_id == ^procedure_id and pp.is_active == true)
    |> Repo.all()
  end

  defp get_std_by_code(code) do
    Procedure
    |> where([p], p.code == ^code)
    |> Repo.one()
  end

  defp get_all_pp_codes do
    PayorProcedure
    |> where([pp], pp.is_active == true)
    |> select([pp], pp.code)
    |> Repo.all()
  end

  defp get_payor_procedure!(id) do
    PayorProcedure
    |> Repo.get!(id)
    |> Repo.preload([
      :payor,
      procedure: :procedure_category
    ])
  end

  def get_procedure(id) do
    Procedure
    |> Repo.get(id)
  end

  def get_payor_procedure(id) do
    PayorProcedure
    |> Repo.get(id)
  end

end
