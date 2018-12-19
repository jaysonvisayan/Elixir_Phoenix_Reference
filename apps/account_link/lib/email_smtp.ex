defmodule Innerpeace.AccountLink.EmailSmtp do
  @moduledoc false

  use Bamboo.Phoenix, view: AccountLinkWeb.EmailView
  import AccountLinkWeb.Router.Helpers
  alias AccountLinkWeb.Endpoint

  def base_email do
    new_email
    |> from("noreply@innerpeace.dev")
    |> put_header("Reply-To", "noreply@innerpeace.dev")
    |> put_html_layout({AccountLinkWeb.LayoutView, "email.html"})
  end

  def invite_user(user) do
    base_email
    |> to(user.email)
    |> subject("User invite")
    |> render("invite_user.html", user: user, url: page_url(Endpoint, :index))
  end

  def reset_password(conn, user) do
    base_email
    |> to(user.email)
    |> subject("Reset Password")
    |> render("reset.html", user: user, url: page_url(Endpoint, :index, conn.assigns.locale))
  end

  def evoucher(member, message) do
    base_email
    |> to(member.email)
    |> subject("ACU E-voucher")
    |> render("evoucher.html", member: member, message: message)
  end

  def evoucher_peme(emails, message, account, url, locale) do
    base_email
    |> to(emails)
    |> subject("Pre Employment Medical Exam (PEME) E-voucher")
    |> render("evoucher_peme.html", emails: emails, message: message, account: account, url: url, locale: locale)
  end

end
