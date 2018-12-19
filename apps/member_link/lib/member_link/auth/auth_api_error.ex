defmodule MemberLink.Auth.Api.ErrorHandler do
  @moduledoc false

  import Phoenix.Controller, only: [put_flash: 3, redirect: 2, put_layout: 2]
  import Plug.Conn

  def auth_error(conn, {type, reason}, opts) do
    body = Poison.encode!(%{error: %{message: "Unauthorized"}})
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, body)
  end
end
