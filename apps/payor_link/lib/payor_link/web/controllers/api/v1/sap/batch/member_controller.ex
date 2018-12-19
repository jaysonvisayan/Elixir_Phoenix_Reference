defmodule Innerpeace.PayorLink.Web.Api.V1.Sap.Batch.MemberController do
  use Innerpeace.PayorLink.Web, :controller
  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.Db.Base.{
    MigrationContext,
    Api.MemberContext
  }

  alias PayorLink.Guardian, as: PG
  alias Innerpeace.PayorLink.Web.Api.V1.Migration.MigrationView
  alias Innerpeace.PayorLink.Web.Endpoint

  def create(conn, params) do
    if is_nil(PG.current_resource_api(conn)) do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please login again to refresh token.")
    else
      user_id = PG.current_resource_api(conn).id
      with {:valid} <- validate_params(params),
           false <- is_nil(user_id)
      do
        members_count =
          params["members"]
          |> Enum.count()

        {:ok, migration} =
          user_id
          |> MigrationContext.start_of_migration(members_count)

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
          "member_batch_migration_job",
          "Innerpeace.Db.Worker.Job.MemberBatchMigrationJob",
          ["Member", url, params, user_id, members_count])

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
  end

  defp validate_params(params) do
    dummy_data = %{}
    general_types = %{
      members: {:array, :map}
    }

    changeset =
      {dummy_data, general_types}
      |> Ecto.Changeset.cast(params, Map.keys(general_types))
      |> validate_required([
        :members
      ])

    if changeset.valid? do
      {:valid}
    else
      {:error, changeset}
    end
  end

  def create_batch(conn,  members) do
    if is_nil(PG.current_resource_api(conn)) do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please login again to refresh token.")
    else
      with true <- Map.has_key?(members, "_json") do
        member = Enum.map(members["_json"], &(MemberContext.create_batch(&1)))
        conn
        |> render(Innerpeace.PayorLink.Web.Api.V1.MemberView, "batch.json", members: member)
      else
        _ ->
          conn
          |> put_status(404)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid Parameters!", code: 404)
      end
    end
  end
end
