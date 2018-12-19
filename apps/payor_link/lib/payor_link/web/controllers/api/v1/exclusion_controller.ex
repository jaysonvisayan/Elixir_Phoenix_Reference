defmodule Innerpeace.PayorLink.Web.Api.V1.ExclusionController do
  @moduledoc false

  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Base.Api.{
    ExclusionContext,
    DiagnosisContext,
    ProcedureContext

  }


  alias Innerpeace.Db.Schemas.{
    Exclusion,
    ExclusionProcedure,
    ExclusionDisease,
    ExclusionDuration,
  }


  alias PayorLink.Guardian, as: PG
  alias Innerpeace.Db.Datatables.ExclusionProcedure, as: EPD

  def index(conn, params) do
    has_exclusion = Map.has_key?(params, "exclusion")
    if Enum.count(params) >= 1 do
      if has_exclusion and is_nil(params["exclusion"]) do
          conn
          |> put_status(404)
          |> render(
            Innerpeace.PayorLink.Web.Api.ErrorView,
            "error.json",
            message: "Please input exclusion name or exclusion code."
          )
      else
          exclusions = ExclusionContext.search_exclusion(params)
          render(conn, "index.json", exclusions: exclusions)
      end
    else
        exclusions = ExclusionContext.search_all_exclusions()
        render(conn, "index.json", exclusions: exclusions)
    end
  end

  def create_custom_exclusion_api(conn, %{"params" => params}) do
    case ExclusionContext.validate_custom_insert(PG.current_resource_api(conn), params) do
      {:precon, exclusion} ->
        render(conn, "precon_exclusion.json", exclusion: exclusion)
      {:ge, exclusion} ->
        render(conn, "exclusion.json", exclusion: exclusion)
      {:error, changeset} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
      {:unauthorized} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Unauthorized")
      _ -> #{:invalid_coverage} ->
        conn
        |> put_status(:not_found)
        |> render(
          Innerpeace.PayorLink.Web.ErrorView,
          "error.json",
          message: "Please enter if the coverage is General Exclusion or Pre-existing Condition."
        )
    end
  end

  def create_general_exclusion_api(conn, %{"params" => params}) do
    case ExclusionContext.validate_general_insert(PG.current_resource_api(conn), params) do
      {:genex, exclusion} ->
        render(conn, "load_genex.json", exclusion: exclusion)
      {:error, changeset} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
      {:unauthorized} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Unauthorized")
      _ -> #{:invalid_coverage} ->
        conn
        |> put_status(:not_found)
        |> render(
          Innerpeace.PayorLink.Web.ErrorView,
          "error.json",
          message: "Please enter if the coverage is General Exclusion or Pre-existing Condition."
        )
    end
  end

  def exclusion_procedure_datatable(conn, %{"exclusion" => ""}) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "exclusion can't be blank")
  end

  def exclusion_procedure_datatable(conn, %{
       "exclusion" => code,
       "length" => length,
       "search" => search,
       "start" => start,
       "order" => order,
       "draw" => draw
      } = params)
  do
    with exclusion = %Exclusion{} <- ExclusionContext.get_exclusion_by_code_or_name(code, false),
         [data, count, filtered_count] <- get_table_data(params, exclusion)
    do
      conn
      |> json(%{
          data: data,
          draw: draw,
          recordsTotal: count,
          recordsFiltered: filtered_count
        })
    end
  end

  defp get_table_data(params, exclusion) do
    data =
      EPD.insert_exclusion_procedure(
        params["start"],
        params["length"],
        params["search"]["value"],
        params["order"]["0"],
        exclusion.id
      )
    count = EPD.procedure_count(exclusion.id)
    filtered_count = EPD.filtered_count(params["search"]["value"], exclusion.id)

    [data, count, filtered_count]
  end

end
