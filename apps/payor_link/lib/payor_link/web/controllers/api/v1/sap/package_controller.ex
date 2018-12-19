defmodule Innerpeace.PayorLink.Web.Api.V1.Sap.PackageController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Base.{
    Api.PackageContext
  }

  alias Innerpeace.Db.Schemas.Package
  alias PayorLink.Guardian, as: PG
  alias Ecto.Changeset
  alias Innerpeace.PayorLink.Web.Endpoint

  def get_packages_by_name_or_code(conn, %{"package" => params}) do
    if is_nil(PG.current_resource_api(conn)) do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please login again to refresh token.")
    else
      with %Package{} = package <- PackageContext.get_packages_by_name_or_code(params) do
          conn
          |> put_status(200)
          |> render(Innerpeace.PayorLink.Web.Api.V1.PackageView, "package.json", package: package)
      else
        nil ->
          conn
          |> put_status(:not_found)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Package Does Not Exist.")

        {:invalid_package} ->
          conn
          |> put_status(:not_found)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid Package Parameter.")

        _ ->
          conn
          |> put_status(:not_found)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
      end
    end
  end

  def get_packages_by_name_or_code(conn, params) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid Parameter")
  end
end
