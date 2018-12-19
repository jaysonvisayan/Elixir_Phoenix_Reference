defmodule Innerpeace.PayorLink.Web.Api.ProductController do
  use Innerpeace.PayorLink.Web, :controller

  # import Ecto.Changeset

  alias Innerpeace.Db.Base.{
    ProductContext,
  }
  alias Innerpeace.Db.Datatables.ExclusionFacilityDatatable

  #for product download
  def download_product(conn, %{"product_param" => download_param}) do
    data = ProductContext.csv_product_downloads(download_param)
    # conn
    json conn, Poison.encode!(data)
  end

  def exclusion_facility_datatable(conn, params) do
    count = ExclusionFacilityDatatable.get_ef_count(params["search"]["value"], params["id"])
    exclusion_facility = ExclusionFacilityDatatable.get_exclusion_facility(params["start"], params["length"], params["search"]["value"], params["id"])
    conn |> json(%{data: exclusion_facility, draw: params["draw"], recordsTotal: count, recordsFiltered: count})
  end

end
