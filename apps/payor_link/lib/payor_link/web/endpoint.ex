defmodule Innerpeace.PayorLink.Web.Endpoint do
  use Phoenix.Endpoint, otp_app: :payor_link

  socket "/socket", Innerpeace.PayorLink.Web.UserSocket

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/", from: :payor_link, gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt semantic themes)

  if Application.get_env(:db, :env) == :dev do
    plug Plug.Static,
    at: "/uploads", from: Path.expand('../../uploads'), gzip: false # point to root of umbrella
  else
    plug Plug.Static,
    at: "/uploads", from: Path.expand('./uploads'), gzip: false
  end

  plug Plug.Static,
    at: "/export", from: Path.expand('./export'), gzip: true

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison,
    length: 100_000_000

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_payor_link_key",
    signing_salt: "dFo3e1A9"

  plug CORSPlug

  plug Innerpeace.PayorLink.Web.Router

  @doc """
  Dynamically loads configuration from the system environment
  on startup.

  It receives the endpoint configuration from the config files
  and must return the updated configuration.
  """
  def load_from_system_env(config) do
    port = System.get_env("PORT") || 4001
    {:ok, Keyword.put(config, :http, [:inet6, port: port])}
  end
end
