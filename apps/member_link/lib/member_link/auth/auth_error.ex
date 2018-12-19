defmodule MemberLink.Auth.ErrorHandler do
  @moduledoc false

  import Phoenix.Controller, only: [put_flash: 3, redirect: 2, put_layout: 2]
  import Plug.Conn

  def auth_error(conn, {type, reason}, _opts) do
    return_url = URI.encode(conn.request_path)
    conn
    |> MemberLink.Guardian.Plug.sign_out
    |> Plug.Conn.configure_session(drop: true)
    |> put_flash(:info, "Please login or register first to continue on the page.")
    |> redirect(to: "/#{conn.assigns.locale}/sign_in?return_url=#{return_url}")
  end
end
