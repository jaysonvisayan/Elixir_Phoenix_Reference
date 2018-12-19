defmodule Innerpeace.Db.Base.Api.CoverageContext do
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
    Base.PackageContext
  }
  alias Ecto.Changeset

  import Ecto.Query

  #API

  def create_coverage(current_user, params) do
    current_user =
      if not is_nil(current_user) do
        current_user = current_user.id
      else
        current_user = ""
      end
    params = Map.put(params, "created_by_id", current_user)
    params = Map.put(params, "updated_by_id", current_user)
    params = Map.put(params, "step", 0)

     # {:ok, changeset} = validate_fields(params)
   # raise changeset |> insert_coverage()

    with {:ok, changeset} <- validate_fields(params),
         {:ok, coverage} <- changeset |> insert_coverage()
    do
      {:ok, coverage}
    else
      {:changeset_error, changeset} ->
        {:changeset_error, changeset}

      _ ->
        {:insert_error, "there something error in inserting a coverage"}
    end
  end

  defp validate_fields(params) do
    types = %{
      name: :string,
      code: :string,
      description: :string,
      status: :string,
      type: :string,
      plan_type: :string,
    }
    changeset =
      {%{}, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([
        :name,
        :code,
        :description,
        :status,
        :type,
        :plan_type
      ], message: "is required")
      |> Changeset.validate_inclusion(:plan_type, [
        "Riders",
        "Health"
      ], message: "is invalid")
      # |> validate_coverages()

    if changeset.valid? do
      {:ok, changeset}
    else
      {:changeset_error, changeset}
    end

  end

  def insert_coverage(changeset) do
    %Coverage{}
    |> Coverage.changeset(changeset.changes)
    |> Repo.insert()
  end

end
