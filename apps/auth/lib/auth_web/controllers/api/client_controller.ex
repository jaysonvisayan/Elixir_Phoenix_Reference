defmodule AuthWeb.API.ClientController do
  use AuthWeb, :controller

  alias Innerpeace.Db.{
    Hydra
  }

  def request(conn, %{"client" => params}) do
    request = %{
      name: params["name"],
      uri: params["uri"],
      logo_uri: params["logo_uri"],
      tos_uri: params["tos_uri"],
      policy_uri: params["policy_uri"],
      owner: params["owner"],
      scopes: params["scopes"],
      response_types: params["response_types"],
      redirect_uris: params["redirect_uris"]
    }
    client = Hydra.create_client(request)

    conn
    |> render("request.json", client: client)
  end
end
