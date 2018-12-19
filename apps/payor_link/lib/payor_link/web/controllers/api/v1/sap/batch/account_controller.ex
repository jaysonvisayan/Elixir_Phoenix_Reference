defmodule Innerpeace.PayorLink.Web.Api.V1.Sap.Batch.AccountController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Base.{
    MigrationContext
  }

  alias PayorLink.Guardian, as: PG
  alias Innerpeace.PayorLink.Web.Api.V1.Migration.MigrationView
  alias Innerpeace.PayorLink.Web.Endpoint

  def create(conn, params) do
    user_id = PG.current_resource_api(conn).id
    with {:valid} <- validate_account_params(params),
         false <- is_nil(user_id)
    do
      accounts_count =
        params["accounts"]
        |> Enum.count()

      {:ok, migration} =
        user_id
        |> MigrationContext.start_post("Account")

      params =
        params
        |> Map.put("migration_id", migration.id)

      url = generate_url(conn)

      Exq.Enqueuer.start_link()

      Exq.Enqueuer
      |> Exq.Enqueuer.enqueue(
        "account_migration_job",
        "Innerpeace.Db.Worker.Job.AccountMigrationJob",
         ["Account", url, params, user_id, accounts_count])

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

  defp validate_account_params(params) do
    general_types = %{
      accounts: {:array, :map}
    }
    changeset =
      {%{}, general_types}
      |> Ecto.Changeset.cast(params, Map.keys(general_types))
      |> Ecto.Changeset.validate_required([
        :accounts
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
