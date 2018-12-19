defmodule Innerpeace.PayorLink.Web.Api.V1.ProductController do
  use Innerpeace.PayorLink.Web, :controller

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.Db.Base.Api.ProductContext
  alias Innerpeace.Db.Base.{
    MigrationContext
  }
  alias PayorLink.Guardian, as: PG

  def load_products(conn, params) do
    # Gets all records of product

    products = ProductContext.get_all_products_queried(params)
    render(conn, Innerpeace.PayorLink.Web.Api.V1.ProductView, "load_all_products.json", products: products)
  end

  # def create_product_api(conn, %{"params" => params}) do
  #   case ProductContext.validate_insert(PG.current_resource_api(conn), params) do
  #     {:ok, product} ->
  #       render(conn, "show.json", product: product)
  #     {:error, changeset} ->
  #       conn
  #       |> put_status(:not_found)
  #       |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
  #     {:not_found} ->
  #       conn
  #       |> put_status(:not_found)
  #       |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
  #     {:invalid_credentials} ->
  #       conn
  #       |> put_status(:not_found)
  #       |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid credentials")
  #   end
  # end

  def create_product_api(conn, %{"params" => params}) do
    with false <- is_nil(conn.private[:guardian_default_resource])
    do
      products_count =
        params
        |> Enum.count()

      module = "Product"

      {:ok, migration} =
      PG.current_resource_api(conn).id
      |> MigrationContext.start_post(module)

      params =
        params
        |> Map.put("migration_id", migration.id)

      Exq.Enqueuer.start_link

      Exq.Enqueuer
      |> Exq.Enqueuer.enqueue(
        "product_migration_job",
        "Innerpeace.Db.Worker.Job.ProductMigrationJob",
        [params, conn.private[:guardian_default_resource].id, products_count])

      url =
        if Application.get_env(:payor_link, :env) == :prod do
          Atom.to_string(conn.scheme) <> "://" <> Innerpeace.PayorLink.Web.Endpoint.struct_url.host
        else
          Innerpeace.PayorLink.Web.Endpoint.url
        end

        render(conn, Innerpeace.PayorLink.Web.Api.V1.Migration.MigrationView, "link.json", link: "#{url}/migration/#{migration.id}/result/#{products_count}")

    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)

      true ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please Login Again to refresh Bearer Token")

    end
  end

  def create_product_api(conn, %{}) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid Parameter")
  end

  def change_member_product(conn, params) do
    case ProductContext.validate_change_member_product(PG.current_resource_api(conn), params) do
      {:ok, result} ->
        render(conn, "change_member_product_result.json", result: result)
      {:error, changeset} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
      {:invalid_credentials} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid credentials")
    end
  end

end
