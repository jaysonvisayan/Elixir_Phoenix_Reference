defmodule Innerpeace.PayorLink.Web.Api.V1.EmailController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.{
    PayorLink.EmailSmtp,
    PayorLink.Mailer,
    PayorLink.Web.Api.ErrorView,
    PayorLink.Web.Api.V1.EmailView,
    Db.Base.MigrationContext
  }

  def send_error_logs(conn, %{"params" => params}) do
    logs = params["logs"]
           |> transforms_to_atom()

    emails = params["emails"]

    with [mails] <- sends_email_for_logs(logs, emails) do
      conn
      |> put_status(200)
      |> render(EmailView, "success.json", message: "Email successfully sent.", code: 200)
    else
      _ ->
        conn
        |> put_status(400)
        |> render(ErrorView, "error.json", message: "Error sending email", code: 400)
    end
  end

  defp transforms_to_atom(logs) do
    Enum.map(logs, fn(log) ->
      log
      |> Enum.reduce(%{}, fn({k, v}, acc) ->
        Map.put(acc, String.to_existing_atom(k), v)
      end)
    end)
  end

  defp sends_email_for_logs(logs, emails) do
    Enum.map(emails, fn(e) ->
      logs
      |> EmailSmtp.error_logs_email(e)
      |> Mailer.deliver_now()
    end)
  end

  def send_migration_details(conn, %{"migration_id" => migration_id}) do
    migration =
      migration_id
      |> MigrationContext.get_migration()

    if is_nil(migration) do
      json(conn, %{valid: false})
    else
      migration
      |> send_email_for_migration()

      json(conn, %{valid: true})

    end

    rescue
      _ ->
      json(conn, %{valid: false})
  end

  defp send_email_for_migration(migration) do
    migration
    |> EmailSmtp.migration_email_notifs()
    |> Mailer.deliver_now()
  end
end
