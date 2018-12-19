defmodule Innerpeace.PayorLink.Web.Api.V1.Vendor.FacilityController do
  use Innerpeace.PayorLink.Web, :controller
  import Ecto.{Query, Changeset}, warn: false

  alias Innerpeace.Db.Base.Api.{
    Vendor.FacilityContext
  }

  @moduledoc false

  def index(conn, params) do
    has_facility = Map.has_key?(params, "facility")
    if Enum.count(params) >= 1 do
      if has_facility and is_nil(params["facility"]) || has_facility && params["facility"] == "" do
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Please input facility name or code.")
      else
        params =
          params
          |> Map.put_new("facility", "")
        
          facility = FacilityContext.search_facility(params)
          filtered_facility = filter_affiliated_practitioner_by_facility(facility)
          if filtered_facility == [] do
            conn
            |> put_status(404)
            |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Facility does not have affiliated practitioner.")
          else
            render(conn, "index.json", facility: filtered_facility)
          end
      end
    else
      facility = FacilityContext.search_all_facility()
      render(conn, "index.json", facility: facility)
    end
  end

  defp filter_affiliated_practitioner_by_facility(facility) do
    result = Enum.map(facility, fn(x) -> 
      Enum.map(x.practitioner_facilities, fn(y) -> 
        if y.practitioner_id != "" do
          x
        end
      end)
    end)

    result = 
      result
      |> Enum.uniq()
      |> List.flatten()
      |> Enum.reject(&(is_nil(&1)))
  end

  def search_facility_by_location(conn, params) do
    has_facility = Map.has_key?(params, "facility")
    if Enum.count(params) >= 1 do
      if has_facility and is_nil(params["facility"]) || has_facility && params["facility"] == "" do
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Please input facility location.")
      else
        params =
          params
          |> Map.put_new("facility", "")
          facility = FacilityContext.search_facility_by_location(params)
          filtered_facility = filter_affiliated_practitioner_by_facility(facility)
          if filtered_facility == [] do
            conn
            |> put_status(404)
            |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Facility does not have affiliated practitioner.")
          else
            render(conn, "index.json", facility: filtered_facility)
          end
      end
    else
      facility = FacilityContext.search_all_facility()
      filtered_facility = filter_affiliated_practitioner_by_facility(facility)
      if filtered_facility == [] do
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Facility does not have affiliated practitioner.")
      else
        render(conn, "index.json", facility: filtered_facility)
      end
    end
  end

end
