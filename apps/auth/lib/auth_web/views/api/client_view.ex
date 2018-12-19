defmodule AuthWeb.API.ClientView do
  use AuthWeb, :view

  def render("request.json", %{client: client}) do
    client
  end
end
