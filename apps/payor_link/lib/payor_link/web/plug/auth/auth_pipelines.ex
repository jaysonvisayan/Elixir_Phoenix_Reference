defmodule PayorLink.Guardian.AuthPipeline.Browser do
  @moduledoc false

  use Guardian.Plug.Pipeline, otp_app: :payor_link,
  module: PayorLink.Guardian,
  error_handler: PayorLink.Auth.ErrorHandler

  plug Guardian.Plug.VerifySession
  plug Guardian.Plug.LoadResource, ensure: true, allow_blank: false
end

defmodule PayorLink.Guardian.AuthPipeline.JSON do
  @moduledoc false

  use Guardian.Plug.Pipeline, otp_app: :payor_link,
  module: PayorLink.Guardian,
  error_handler: PayorLink.Auth.Api.ErrorHandler

  plug Guardian.Plug.VerifyHeader, realm: "Bearer"
  plug Guardian.Plug.LoadResource, allow_blank: true
end

defmodule PayorLink.Guardian.AuthPipeline.Authenticate do
  @moduledoc false

  alias PayorLink.Guardian, as: PG
  import Guardian.Plug
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  use Guardian.Plug.Pipeline, otp_app: :payor_link,
  module: PayorLink.Guardian,
  error_handler: PayorLink.Auth.ErrorHandler

  plug Guardian.Plug.EnsureAuthenticated
  # plug Auth.SlidingSessionTimeout, timeout_after_seconds: 10_000

  def call(conn, _opts) do
    current_user = PG.current_resource(conn)
    case current_user do
      nil ->
        conn
        |> logout
      _ ->
        conn
    end
  end

  defp logout(conn) do
    conn
    |> Plug.Conn.delete_resp_cookie("nova", [
        secure: get_secure_by_env(),
        http_only: true,
        domain: conn.host
      ])
    |> PayorLink.Guardian.Plug.sign_out
    |> Plug.Conn.configure_session(drop: true)
    |> Plug.Conn.clear_session()
    |> put_flash(:info, "Logged out")
    |> redirect(to: "/")
  end

  defp get_secure_by_env do
    case Application.get_env(:payor_link, :env) do
      :prod ->
        true
       _ ->
        false
    end
  end
end
