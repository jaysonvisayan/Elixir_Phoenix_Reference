defmodule Innerpeace.PayorLink.EmailSmtp do
  @moduledoc false

  use Bamboo.Phoenix, view: Innerpeace.PayorLink.Web.EmailView
  import Innerpeace.PayorLink.Web.Router.Helpers
  alias Innerpeace.PayorLink.Web.Endpoint
  alias Innerpeace.Db.Base.AcuScheduleContext

  def base_email do
    new_email
    |> from("MAXICARE@noreply.com.ph")
    |> put_header("Reply-To", "MAXICARE@noreply.com.ph")
    |> put_html_layout({Innerpeace.PayorLink.Web.LayoutView, "email.html"})
  end

  def invite_user(user) do
    base_email
    |> to(user.email)
    |> subject("User invite")
    |> render("invite_user.html", user: user, url: page_url(Endpoint, :index))
  end

  def reset_password(user) do
    base_email
    |> to(user.email)
    |> subject("Reset Password")
    |> render("reset.html", user: user, url: page_url(Endpoint, :index))
  end

  def evoucher(member, message) do
    base_email
    |> to(member.email)
    |> subject("Maxicare Annual Check Up eVoucher")
    |> render("evoucher.html", member: member, message: message)
  end

  def migration_email_notifs(migration) do
    base_email
    |> to(migration.user.email)
    |> subject("Migration Results")
    |> render(
      "migration_notification.html",
      migration: migration
    )
  end

  def migration_email_fail_notifs(migration, migration_notification_false) do
    base_email
    |> to(migration.user.email)
    |> subject("Migration Results")
    |> render(
      "migration_fail_notification.html",
      migration: migration,
      migration_notification_false: migration_notification_false
    )
  end

  def error_logs_email(worker_error_log, email) do
    base_email
    |> to(email)
    |> subject("Error Log")
    |> render(
      "error_log.html", worker_error_log: worker_error_log, email: email, url: page_url(Endpoint, :index)
    )
  end

  def user_activation_notif(message, user) do
    base_email
    |> to(user.email)
    |> subject("Upload file notification")
    |> render("user_activation_notif.html", message: message, user: user, url: page_url(Endpoint, :index))
  end

  ##### email #####
  def send_acu_email(acu_schedule, date_inserted) do
    #acu_sched = AcuScheduleContext.get_acu_schedule(acu_schedule.id)
    values = %{id: acu_schedule.id, datetime: date_inserted}
    val = Poison.encode!(values)

    base_email
    |> to(acu_schedule.facility.email_address)
    |> subject("ACU Schedule-<%= @acu_schedule.batch_no %>-<%= @acu_schedule.account_group.name %>")
    |> render("acu_schedule_notification.html", acu_schedule: acu_schedule, val: val)
  end

end
