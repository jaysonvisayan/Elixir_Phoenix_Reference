defmodule Innerpeace.PayorLink.Web.Api.V1.Sap.ProductController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Base.{
    MigrationContext,
    Api.ProductContext
  }
  alias Innerpeace.Db.Base.Api.Sap.ProductContext, as: SapPC

  alias Ecto.Changeset
  alias PayorLink.Guardian, as: PG
  alias Innerpeace.PayorLink.Web.Endpoint

  def create(conn, %{"params" => params}) do
    if is_nil(PG.current_resource_api(conn)) do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please login again to refresh token.")
    else
      user = PG.current_resource_api(conn)
      case ProductContext.validate_insert(user, params) do
        {:ok, product} ->
          conn
          |> render(Innerpeace.PayorLink.Web.Api.V1.ProductView, "show.json", product: product)

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

  def create(conn, params) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid Parameters")
  end

  def create_dental(conn, params) do
    user = PG.current_resource_api(conn)

    validate_plan(user, conn, params)
  end

  defp validate_plan(nil, conn, params), do: error_renderer(conn, "Please login again to refresh token.")
  defp validate_plan(user, conn, params) do
    case SapPC.insert_dental_plan(user, params) do
      {:ok, product} ->
        conn
        |> render(Innerpeace.PayorLink.Web.Api.V1.ProductView, "show_dental.json", product: product)
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "changeset_error.json", message: changeset, code: 400)
      {:error_creating_product} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "error.json", message: "Error in Creating Dental Plan", code: 400)
      {:product_base_invalid} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "error.json", message: "Product Base is required", code: 400)
      _ ->
        error_renderer(conn, "Not Found")
    end
  end

  defp error_renderer(conn, message) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: message)
  end

  def get_dental(conn, params) do
    if is_nil(PG.current_resource_api(conn)) do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please login again to refresh token.")
    else
      user = PG.current_resource_api(conn)
      case SapPC.get_product_dental(conn, params["code"]) do
        {:ok, product} ->
          conn
          |> render(Innerpeace.PayorLink.Web.Api.V1.ProductView, "show_dental.json", product: product)

        {:error, changeset} ->
          conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "changeset_error.json", message: changeset, code: 400)

        _ ->
          conn
          |> put_status(:not_found)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid Dental Product Code!")
      end
    end
  end

end
