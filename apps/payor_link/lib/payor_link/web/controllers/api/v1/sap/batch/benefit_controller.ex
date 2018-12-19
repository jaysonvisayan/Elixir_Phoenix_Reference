defmodule Innerpeace.PayorLink.Web.Api.V1.Sap.Batch.BenefitController do
  use Innerpeace.PayorLink.Web, :controller


  alias Innerpeace.Db.Base.{
    MigrationContext
  }
  alias PayorLink.Guardian, as: PG
  alias Innerpeace.PayorLink.Web.Api.V1.Migration.MigrationView
  alias Innerpeace.PayorLink.Web.Endpoint

  def create(conn, params) do
    user_id = PG.current_resource_api(conn).id
    with {:valid} <- validate_benefit_params(params),
         false <- is_nil(user_id)
    do
      benefits_count =
        params["benefits"]
        |> Enum.count()

      module = "Benefit"

      {:ok, migration} =
        user_id
      |> MigrationContext.start_post(module)

      params =
        params
        |> Map.put("migration_id", migration.id)


      url =
        if Application.get_env(:payor_link, :env) == :prod do
          Atom.to_string(conn.scheme) <> "://" <> Innerpeace.PayorLink.Web.Endpoint.struct_url.host
        else
          Innerpeace.PayorLink.Web.Endpoint.url
        end

      Exq.Enqueuer.start_link

      Exq.Enqueuer
      |> Exq.Enqueuer.enqueue(
        "benefit_batch_migration_job",
        "Innerpeace.Db.Worker.Job.BenefitBatchMigrationJob",
        ["Benefit", url, params, user_id, benefits_count])

      conn
      |> render(MigrationView, "link.json", link: "#{url}/migration/#{migration.id}/results")

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

  defp validate_benefit_params(params) do
    dummy_data = %{}
    general_types = %{
      benefits: {:array, :map}
    }

    changeset =
      {dummy_data, general_types}
      |> Ecto.Changeset.cast(params, Map.keys(general_types))
      |> Ecto.Changeset.validate_required([
        :benefits
      ])

    if changeset.valid? do
      {:valid}
    else
      {:error, changeset}
    end

  end
end
