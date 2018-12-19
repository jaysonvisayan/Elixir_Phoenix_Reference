defmodule Innerpeace.PayorLink.Web.Api.V1.Sap.BenefitController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Base.{
    MigrationContext,
    Api.BenefitContext,
    Api.UtilityContext
  }

  alias Innerpeace.Db.Schemas.Benefit
  alias Innerpeace.Db.Datatables.BenefitDatatable, as: BD
  alias Innerpeace.Db.Base.BenefitContext, as: WebBenefitContext
  alias Innerpeace.Db.Base.Api.BenefitContext, as: WBCApi
  alias Innerpeace.Db.Base.Api.Sap.BenefitContext, as: SapBenefitContext
  alias Ecto.Changeset
  alias PayorLink.Guardian, as: PG
  alias Innerpeace.PayorLink.Web.Endpoint

  def create(conn, benefit_params) do
    if is_nil(PG.current_resource_api(conn)) do
      ### SAP C4C ticketing
      "Please login again to refresh token." |> UtilityContext.sap_c4c_ticketing(conn.request_path, 404, conn |> get_url_by_env())

      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please login again to refresh token.")
    else
      type = String.capitalize("#{benefit_params["type"]}")
      user_id = PG.current_resource_api(conn).id
      with {:ok, benefit} <- BenefitContext.create_benefit(%{id: user_id}, benefit_params, type) do
        conn
        |> put_status(200)
        |> render(Innerpeace.PayorLink.Web.Api.V1.BenefitView, "benefit.json", benefit: benefit)

      else
        {:error, changeset} ->
          ### SAP C4C ticketing
          changeset |> UtilityContext.sap_c4c_ticketing(conn.request_path, 400, conn |> get_url_by_env())

          conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "changeset_error.json", message: changeset, code: 400)

        {:error_type} ->
          ### SAP C4C ticketing
          "Benefit Type Not Found/Invalid." |> UtilityContext.sap_c4c_ticketing(conn.request_path, 400, conn |> get_url_by_env())

          conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Benefit Type Not Found/Invalid.")

        _ ->
          ### SAP C4C ticketing
          "Not Found" |> UtilityContext.sap_c4c_ticketing(conn.request_path, 404, conn |> get_url_by_env())

          conn
          |> put_status(:not_found)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
      end
    end

    rescue
    error ->
        conn
        |> PG.current_resource_api()
        |> send_error_to_sentry(error)

        ### SAP C4C ticketing
        "internal server error" |> UtilityContext.sap_c4c_ticketing(conn.request_path, 500, conn |> get_url_by_env())

        conn
        |> put_status(500)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Internal Server Error")
  end

  def get_benefits(conn, %{"benefits" => ""}) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Benefits can't be blank.")
  end

  def get_benefits(conn, %{"benefits" => params}) do
    benefits = WebBenefitContext.get_benefit_by_code_or_name(params)
    with true <- not is_nil(benefits) do
        conn
        |> put_status(200)
        |> render(Innerpeace.PayorLink.Web.Api.V1.BenefitView, "get_benefits.json", benefits: benefits)
    else
      _->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Benefit not existing.")
    end
  end

  def get_dental(conn, %{"benefit" => ""}) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "benefit code can't be blank")
  end

  def get_dental(conn, %{
    "benefit" => code,
    "with_cdt" => with_cdt?,
    "length" => length,
    "search" => search,
    "start" => start,
    "order" => order,
    "draw" => draw
  } = params)
  do
    with benefit_dental = %Benefit{} <- WebBenefitContext.get_benefit_dental_by_code_or_name(code, nil, true),
         [data, count, filtered_count] <- get_benefit_dental_table_data(params, benefit_dental, with_cdt?)
    do
      conn
      |> json(%{
          data: data,
          draw: draw,
          recordsTotal: count,
          recordsFiltered: filtered_count
        })

    else
      _ ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Benefit dental not found.")

    _ ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid Dental Benefit Code or Name!")
    end

  end

  defp get_benefit_dental_table_data(params, benefit_dental, "true") do
    data =
      BD.get_dental_benefit_procedure(
      params["start"],
      params["length"],
      params["search"]["value"],
      params["order"]["0"],
      benefit_dental.id
      )
      count = BD.get_dental_benefit_procedure_count(benefit_dental.id)
      filtered_count = BD.get_dental_benefit_procedure_filtered_count(params["search"]["value"], benefit_dental.id)

      [data, count, filtered_count]
  end

  def get_dental(conn, params) do
    if is_nil(PG.current_resource_api(conn)) do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please login again to refresh token.")
    else
      user = PG.current_resource_api(conn)
      case WBCApi.get_benefit_dental(params["benefit"], params["procedure_page_number"], params["with_cdt"]) do
        {:ok, benefit} ->
          conn
          |> render(Innerpeace.PayorLink.Web.Api.V1.BenefitView, "show_dental_benefit.json", benefits: benefit)

        {:error, changeset} ->
          conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "changeset_error.json", message: changeset, code: 400)

        _ ->
          conn
          |> put_status(:not_found)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid Dental Benefit Code or Name!")
      end
    end
  end

  def create_sap_dental(conn, params) do
    with false <- is_nil(PG.current_resource_api(conn)),
         user <- PG.current_resource_api(conn),
         {:ok, benefit} <- SapBenefitContext.create_sap_dental(user, params)
    do
      conn
      |> put_status(200)
      |> render(Innerpeace.PayorLink.Web.Api.V1.BenefitView, "sap_dental_benefit.json", benefit: benefit)
    else
      true ->
        ### SAP C4C ticketing
        # "Please login again to refresh token." |> UtilityContext.sap_c4c_ticketing(conn.request_path, 404, conn |> get_url_by_env())

        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please login again to refresh token.")

      {:error, changeset} ->
        ### SAP C4C ticketing
        # changeset |> UtilityContext.sap_c4c_ticketing(conn.request_path, 400, conn |> get_url_by_env())

        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "changeset_error.json", message: changeset, code: 400)

      _ ->
        ### SAP C4C ticketing
        # "Not Found" |> UtilityContext.sap_c4c_ticketing(conn.request_path, 404, conn |> get_url_by_env())

        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
    end

    rescue
    error ->
        conn
        |> PG.current_resource_api()
        |> send_error_to_sentry(error)

        ### SAP C4C ticketing
        "internal server error" |> UtilityContext.sap_c4c_ticketing(conn.request_path, 500, conn |> get_url_by_env())

        conn
        |> put_status(500)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Internal Server Error")

  end

  defp send_error_to_sentry(user, err_msg) do
    err_msg
    |> Sentry.capture_exception([
      stacktrace: System.stacktrace(),
      tags: %{
        "app_version" => "#{Application.spec(:payor_link, :vsn)}",
        "user_id" => user.id,
        "username" => user.username
      }
    ])
  end

  def get_url_by_env(conn) do
    if Application.get_env(:payor_link, :env) == :prod do
      Atom.to_string(conn.scheme) <> "://" <> Endpoint.struct_url.host
    else
      Endpoint.url
    end
  end

end
