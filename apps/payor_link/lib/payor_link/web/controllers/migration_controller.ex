defmodule Innerpeace.PayorLink.Web.MigrationController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Base.{
    MigrationContext
  }

  alias Innerpeace.PayorLink.Web.MigrationView

  def result(conn, %{"id" => id, "count" => count}) do
    migration = MigrationContext.get_migration(id)

    if migration.user.id == conn.assigns.current_user.id do
      migration_notification = MigrationContext.get_migration_notification(migration)

      render(conn, "results.json", results: migration_notification, count: count)
    else

      conn
      |> put_flash(:error, "You are not allowed to access the page")
      |> redirect(to: "/")
    end
  end

  def results(conn, %{"id" => id}) do
    migration = MigrationContext.get_migration(id)
    generate_result(conn, migration)
  end

  defp generate_result(conn, migration) when is_nil(migration) do
    conn
    |> put_flash(:error, "Migration does not exist")
    |> redirect(to: "/")
  end

  defp generate_result(conn, migration) when not is_nil(migration) do
    migration_notification = MigrationContext.get_migration_notification(migration)
    if migration.user.id == conn.assigns.current_user.id do
      render(conn,
        "migration_notification.html",
        migration: migration,
        migration_notification_false: migration_notification
      )
    else
      conn
      |> put_flash(:error, "You are not allowed to access the page")
      |> redirect(to: "/")
    end
  end

  def download_migration(conn, %{"migration_param" => download_param}) do
    data = [["#", "IS SUCCESS", "DETAILS"]] ++ MigrationContext.csv_downloads(download_param)
             |> CSV.encode()
             |> Enum.to_list()
             |> to_string()

    conn
    |> json(data)
  end

  def result_v2(conn, %{"id" => id}), do:
    conn |> render("result_v2.json", migration: MigrationContext.get_migration(id))

end
