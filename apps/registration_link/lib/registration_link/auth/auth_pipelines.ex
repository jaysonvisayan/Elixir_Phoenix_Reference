defmodule RegistrationLink.Guardian.AuthPipeline.Browser do
  @moduledoc false
  use Guardian.Plug.Pipeline, otp_app: :registration_link,
  module: RegistrationLink.Guardian,
  error_handler: RegistrationLink.Auth.ErrorHandler

  plug Guardian.Plug.VerifySession
  plug Guardian.Plug.LoadResource, ensure: true, allow_blank: false
end

defmodule RegistrationLink.Guardian.AuthPipeline.JSON do
  @moduledoc false
  use Guardian.Plug.Pipeline, otp_app: :registration_link,
  module: RegistrationLink.Guardian,
  error_handler: RegistrationLink.Auth.ErrorHandler

  plug Guardian.Plug.VerifyHeader, realm: "Bearer"
  plug Guardian.Plug.LoadResource, allow_blank: true
end

defmodule RegistrationLink.Guardian.AuthPipeline.Authenticate do
  @moduledoc false
  import Guardian.Plug
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  use Guardian.Plug.Pipeline, otp_app: :registration_link,
  module: RegistrationLink.Guardian,
  error_handler: RegistrationLink.Auth.ErrorHandler

  plug Guardian.Plug.EnsureAuthenticated

  def call(conn, _opts) do
    current_user = conn |> current_resource
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
    |> RegistrationLink.Guardian.Plug.sign_out
    |> Plug.Conn.configure_session(drop: true)
    |> put_flash(:info, "Logged out")
    |> redirect(to: "/")
  end
end
