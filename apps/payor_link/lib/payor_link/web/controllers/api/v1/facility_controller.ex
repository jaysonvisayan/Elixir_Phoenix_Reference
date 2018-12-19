defmodule Innerpeace.PayorLink.Web.Api.V1.FacilityController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Base.Api.{
    FacilityContext
  }
  alias Innerpeace.Db.Schemas.Facility
  alias PayorLink.Guardian, as: PG

  def create_facility_api(conn, %{"params" => params}) do
    case FacilityContext.validate_insert(PG.current_resource_api(conn), params) do
      {:ok, facility} ->
        render(conn, "show.json", facility: facility)
      {:error, changeset} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
      {:not_found} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
    end
  end

  def create_facility_api(conn, params) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid Parameters")
  end

  def get_facility_by_vendor_code(conn, params) do
    if params == %{} do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Vendor code is empty.")
    else
      if is_nil(params["vendor_code"]) do
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Vendor code is empty.")
      else
        vendor_code = params["vendor_code"]
        facility_code = FacilityContext.get_facility_code_by_vendor_code(vendor_code)
        if facility_code != "" do
          render(conn, Innerpeace.PayorLink.Web.Api.V1.FacilityView, "vendor_code.json", code: facility_code)
        else
          conn
          |> put_status(:not_found)
          |> render(
            Innerpeace.PayorLink.Web.ErrorView,
            "error.json",
            message: "There was no facility having the given vendor code."
          )
        end
      end
    end
  end

  def index(conn, params) do
    has_facility = Map.has_key?(params, "facility")
    if Enum.count(params) >= 1 do
      if has_facility and is_nil(params["facility"]) || has_facility and params["facility"] == "" do
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Please input facility name or code.")
      else
        params =
          params
          |> Map.put_new("facility", "")
          facility = FacilityContext.search_facility(params)
          render(conn, "index.json", facility: facility)
      end
    else
      facility = FacilityContext.search_all_facility()
      render(conn, "index.json", facility: facility)
    end
  end

   def get_facility_by_id(conn, %{"params" => %{"facility_id" => facility_id}}) do
    with {:ok, facility} <- Innerpeace.Db.Base.FacilityContext.get_facility(facility_id) do
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.FacilityView, "facility.json", facility: facility)
    else
      {:error, _changeset} ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Facility not found", code: 404)
    end
  end

  def get_facility_by_code(conn, params) do
    with false <- is_nil(params["code"]),
         facility = %Facility{} <- FacilityContext.get_facility_by_code(params["code"])
    do
      render(conn, "facility2.json", facility: facility)
    else
     _ ->
      error_msg(conn, "Facility not found", 404)
    end
  end

  defp error_msg(conn, message, status) do
    conn
    |> put_status(status)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: message, code: status)
  end

end
