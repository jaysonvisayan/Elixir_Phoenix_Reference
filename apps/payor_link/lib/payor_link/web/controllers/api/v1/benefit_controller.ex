defmodule Innerpeace.PayorLink.Web.Api.V1.BenefitController do
  use Innerpeace.PayorLink.Web, :controller

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.Db.Base.Api.{
    BenefitContext
  }
  alias Innerpeace.Db.Base.{
    MigrationContext
  }

  alias PayorLink.Guardian, as: PG

  # def create(conn, params) do
  #   user = Guardian.PG.current_resource_api(conn)
  #   if user do
  #     case BenefitContext.create_benefit(Guardian.PG.current_resource_api(conn), params) do
  #       {:ok, benefit} ->
  #         conn
  #         |> render(Innerpeace.PayorLink.Web.Api.V1.BenefitView, "benefit.json", benefit: benefit)
  #       {:error, message} ->
  #         conn
  #         |> put_status(400)
  #         |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: message)

  #       # {:error, changeset} ->
  #         #   conn
  #         #   |> put_status(400)
  #         #   |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
  #     end
  #   else
  #     conn
  #     |> put_status(400)
  #     |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Please login again to refresh your Token.")
  #   end
  # end

  def create(conn, params) do
    with false <- is_nil(conn.private[:guardian_default_resource])
   do

      benefits_count =
        params
        |> Enum.count()

      {:ok, migration} =
        PG.current_resource_api(conn).id
        |> MigrationContext.start_of_migration(1)

      params =
        params
        |> Map.put("migration_id", migration.id)

      Exq.Enqueuer.start_link

      Exq.Enqueuer
      |> Exq.Enqueuer.enqueue(
        "benefit_migration_job",
        "Innerpeace.Db.Worker.Job.BenefitMigrationJob",
        [params, PG.current_resource_api(conn).id, 1])

      url =
        if Application.get_env(:payor_link, :env) == :prod do
          Atom.to_string(conn.scheme) <> "://" <> Innerpeace.PayorLink.Web.Endpoint.struct_url.host
        else
          Innerpeace.PayorLink.Web.Endpoint.url
        end

        render(conn,  Innerpeace.PayorLink.Web.Api.V1.Migration.MigrationView, "link.json", link: "#{url}/migration/#{migration.id}/result/#{benefits_count}")

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

  def index(conn, params) do
    has_benefit = Map.has_key?(params, "benefit")
    if Enum.count(params) >= 1 do
      cond do
        has_benefit == false ->
          conn
          |> put_status(404)
          |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Invalid parameters!")
        has_benefit == true and is_nil(params["benefit"]) ->
          conn
          |> put_status(404)
          |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Please input benefit name or code.")
        true ->
          params =
            params
            |> Map.put_new("benefit", "")
            benefit = BenefitContext.search_benefits(params)
            render(conn, "index.json", benefit: benefit)
      end
      else
        benefit = BenefitContext.get_all_benefit()
        render(conn, "index.json", benefit: benefit)
    end
  end
end
