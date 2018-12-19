defmodule Innerpeace.PayorLink.Web.Api.V1.Sap.ExclusionController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.{
    Base.Api.ExclusionContext,
    Schemas.Diagnosis,
    Schemas.Exclusion
  }

  alias Innerpeace.Db.Base.Api.UtilityContext, as: UC
  alias Innerpeace.Db.Datatables.ExclusionDiseaseDatatable, as: EDD
  alias Innerpeace.Db.Datatables.ExclusionCondition, as: ECD

  alias Ecto.Changeset
  alias PayorLink.Guardian, as: PG

  action_fallback Innerpeace.PayorLink.Web.ExclusionFallbackController

  def create_pre_existing(conn, params) do
    condition = if params["conditions"] == "" || Enum.empty?(params["conditions"]), do: true, else: false
    if is_nil(PG.current_resource_api(conn)) do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please login again to refresh token.")
    else
      user = PG.current_resource_api(conn)
      case ExclusionContext.create_pre_existing(params, user) do
        {:ok, exclusion} ->         
          conn
          |> render(Innerpeace.PayorLink.Web.Api.V1.ExclusionView, "pre_existing.json", exclusion: exclusion, condition: condition)

        {:error, changeset} ->
          conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "changeset_errors.json", message: changeset, code: 400)

        _ ->
          conn
          |> put_status(:not_found)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
      end
    end
  end

  def get_sap_pre_existing(conn, %{"pre_existing" => ""}) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Enter pre existing code")
  end

  def get_sap_pre_existing(conn, %{
       "pre_existing" => code,
       "with_diagnosis" => with_diagnosis?,
       "member_type" => member_type,
       "length" => length,
       "search" => search,
       "start" => start,
       "order" => order,
       "draw" => draw
      } = params)
  do
    with exclusion = %Exclusion{} <- ExclusionContext.get_exclusion_by_code_or_name(code, false),
         [data, count, filtered_count] <- get_table_data(params, exclusion, with_diagnosis?)
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

  def get_sap_pre_existing(conn, %{
       "pre_existing" => code,
       "with_diagnosis" => with_diagnosis?,
       "length" => length,
       "search" => search,
       "start" => start,
       "order" => order,
       "draw" => draw
      } = params)
  do
    with exclusion = %Exclusion{} <- ExclusionContext.get_exclusion_by_code_or_name(code, false),
         [data, count, filtered_count] <- get_table_data(params, exclusion, with_diagnosis?)
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

  def get_sap_pre_existing(conn, params) do
    code = params["pre_existing"]
    with_diagnosis? = params["with_diagnosis"]

    case ExclusionContext.get_exclusion_by_code_or_name(code, with_diagnosis?) do
      {:ok, exclusion} ->
        conn
        |> render(Innerpeace.PayorLink.Web.Api.V1.ExclusionView, "sap_exclusion.json", exclusion: exclusion)

      {:error, message} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: message)

      _ ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
    end
  end

  defp get_table_data(params, exclusion, "true") do
    data =
      EDD.insert_diagnosis_exclusion(
        params["start"],
        params["length"],
        params["search"]["value"],
        params["order"]["0"],
        exclusion.id
      )
    count = EDD.disease_count(exclusion.id)
    filtered_count = EDD.get_disease_filtered_count(params["search"]["value"], exclusion.id)

    [data, count, filtered_count]
  end

  defp get_table_data(params, exclusion, _) do
    data =
      ECD.insert_exclusion_condition(
        params["start"],
        params["length"],
        params["search"]["value"],
        params["order"]["0"],
        exclusion.id,
        params["member_type"]
      )
    count = ECD.count(exclusion.id)
    filtered_count = ECD.get_filtered_count(params["search"]["value"], exclusion.id)

    [data, count, filtered_count]
  end

  def create_exclusion(conn, params) do
    if is_nil(PG.current_resource_api(conn)) do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please login again to refresh token.")
    else
      user = PG.current_resource_api(conn)
      case ExclusionContext.create_exclusion(params, user) do
        {:ok, exclusion} ->
          conn
          |> render(Innerpeace.PayorLink.Web.Api.V1.ExclusionView, "create_sap_exclusion.json", exclusion: exclusion)

        {:error, changeset} ->
          conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "changeset_error.json", message: changeset, code: 400)

        _ ->
          conn
          |> put_status(:not_found)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
      end
    end
  end

  def get_exclusion(conn, %{"code" => code}) do
    # raise ExclusionContext.get_exclusion_by_code(code)
    if is_nil(PG.current_resource_api(conn)) do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please login again to refresh token.")
    else
      exclusion = ExclusionContext.get_exclusion_by_code_sap(code)
      if exclusion do
        conn
        |> render(Innerpeace.PayorLink.Web.Api.V1.ExclusionView, "get_sap_exclusion.json", exclusion: exclusion)
      else
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error2.json", message: "Not Found")
      end
    end
  end

  def get_exclusion(conn, params) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please enter code")
  end

end
