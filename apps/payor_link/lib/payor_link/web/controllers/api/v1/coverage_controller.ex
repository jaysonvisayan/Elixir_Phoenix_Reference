defmodule Innerpeace.PayorLink.Web.Api.V1.CoverageController do
  use Innerpeace.PayorLink.Web, :controller
  alias Innerpeace.Db.Base.Api.{
    CoverageContext
  }

  def create_coverage_api(conn, params) do
    user = PayorLink.Guardian.current_resource_api(conn)
    if user do
      case CoverageContext.create_coverage(user, params) do
        {:ok, coverage} ->
          conn
          |> render(Innerpeace.PayorLink.Web.Api.V1.CoverageView, "coverage.json", coverage: coverage)
        {:error, message} ->
          conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: message)

        {:insert_error, message} ->
          conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: message)

           end
    else
      conn
      |> put_status(400)
      |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Please login again to refresh your Token.")
    end
  end
end
