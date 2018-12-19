defmodule RegistrationLink.Auth.ErrorHandler do
  @moduledoc false
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2, put_layout: 2]
  import Plug.Conn

  def auth_error(conn, {_type, _reason}, _opts) do
    #return_url = URI.encode(conn.request_path)
    conn
    |> put_flash(:info, "Please login or register first to continue on the page.")
    |> redirect(to: "/sign_in")
  end
end
