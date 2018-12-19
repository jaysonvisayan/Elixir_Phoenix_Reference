defmodule Auth.ErrorHandler do
  @moduledoc false

  import Plug.Conn

  def auth_error(conn, {type, reason}, _opts) do
    # No need to handle anything here
    conn
  end
end

defmodule Auth.Guardian.AuthPipeline.Browser do
  @moduledoc false

  use Guardian.Plug.Pipeline,
    otp_app: :auth,
    module: Auth.Guardian,
    error_handler: Auth.ErrorHandler

  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.LoadResource, allow_blank: true
end
