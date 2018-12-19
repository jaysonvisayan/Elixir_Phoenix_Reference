defmodule AuthWeb.DemoController do
  use AuthWeb, :controller

  alias Innerpeace.Db.Hydra

  def index(conn, %{
    "client_id" => client_id,
    "client_secret" => client_secret,
    "redirect_url" => redirect_url
  }) do
    url =
      OAuth2.Client.authorize_url!(
        client(client_id, client_secret, redirect_url),
        scope: "openid",
        state: "dfadfafdfadagdagdfkadfam"
      )

    conn
    |> redirect(external: url)
  end

  def token(conn, %{
    "code" => code,
    "client_id" => client_id,
    "client_secret" => client_secret,
    "redirect_url" => redirect_url
  }) do

    token =
      client_id
      |> client(client_secret, redirect_url)
      |> Hydra.get_token(code)

    conn
    |> render("token.json", token: token)
  end

  def client(client_id, client_secret, redirect_url) do
    Hydra.initialize(
      client_id,
      client_secret,
      redirect_url
    )
  end
end
