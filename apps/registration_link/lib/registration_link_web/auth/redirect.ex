defmodule RegistrationLinkWeb.Redirect do
  @moduledoc false

  import Phoenix.Controller, only: [put_flash: 3, redirect: 2, put_layout: 2]
  import Plug.Conn

  def init(opts), do: opts
  def call(conn, _opts) do
    current_user = conn.assigns.current_user
    if is_nil(current_user) do
      conn
      |> redirect(to: "#{conn.assigns.locale}/sign_in")
    else
      conn
    end
  end
end
