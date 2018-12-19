defmodule Innerpeace.PayorLink.Web.Api.V1.Sap.Batch.ProductController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Base.Api.{
    BenefitContext,
    UtilityContext
  }
  alias Innerpeace.Db.Base.{
    MigrationContext
  }

  alias PayorLink.Guardian, as: PG
  alias Innerpeace.PayorLink.Web.Api.V1.Migration.MigrationView
  alias Innerpeace.PayorLink.Web.Endpoint

  def create(conn, params) do
    user_id = PG.current_resource_api(conn).id
    with {:valid} <- validate_product_params(params),
         false <- is_nil(user_id)
    do
      products_count =
        params["products"]
        |> Enum.count()

      {:ok, migration} =
        user_id
        |> MigrationContext.start_post("Product")

      params =
        params
        |> Map.put("migration_id", migration.id)

      url = generate_url(conn)

      Exq.Enqueuer.start_link

      Exq.Enqueuer
      |> Exq.Enqueuer.enqueue(
        "product_batch_migration_job",
        "Innerpeace.Db.Worker.Job.ProductBatchMigrationJob",
        ["Product", url, params, user_id, products_count])

      render(conn, MigrationView, "link.json", link: "#{url}/migration/#{migration.id}/results")
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

  defp validate_product_params(params) do
    general_types = %{
      products: {:array, :map}
    }
    changeset =
      {%{}, general_types}
      |> Ecto.Changeset.cast(params, Map.keys(general_types))
      |> Ecto.Changeset.validate_required([
        :products
      ])
    if changeset.valid? do
      {:valid}
    else
      {:error, changeset}
    end
  end

  defp generate_url(conn) do
    if Application.get_env(:payor_link, :env) == :prod do
      Atom.to_string(conn.scheme) <> "://" <> Innerpeace.PayorLink.Web.Endpoint.struct_url.host
    else
      Endpoint.url()
    end
  end

end

