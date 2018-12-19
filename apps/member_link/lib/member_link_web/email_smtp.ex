defmodule Innerpeace.MemberLink.EmailSmtp do
  @moduledoc false
  use Bamboo.Phoenix, view: MemberLinkWeb.EmailView
  import MemberLinkWeb.Router.Helpers
  alias MemberLinkWeb.Endpoint

  def base_email do
    new_email
    |> from("noreply@innerpeace.dev")
    |> put_header("Reply-To", "noreply@innerpeace.dev")
    |> put_html_layout({MemberLinkWeb.LayoutView, "email.html"})
  end

  def invite_user(user) do
    base_email
    |> to(user.email)
    |> subject("User invite")
    |> render("invite_user.html", user: user, url: page_url(Endpoint, :index, "en"))
  end

  def reset_password(user) do
    base_email
    |> to(user.email)
    |> subject("Reset Password")
    |> render("reset.html", user: user, url: page_url(Endpoint, :index, "en"))
  end

  def forgot_username(user) do
    base_email
    |> to(user.email)
    |> subject("Forgot Username")
    |> render("forgot_username.html", user: user, url: page_url(Endpoint, :index, "en"))
  end

  def forgot_password(user) do
    base_email
    |> to(user.email)
    |> subject("Forgot Password")
    |> render("forgot_password.html", user: user, url: page_url(Endpoint, :index, "en"))
  end
end
