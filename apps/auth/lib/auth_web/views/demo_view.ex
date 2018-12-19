defmodule AuthWeb.DemoView do
  use AuthWeb, :view

  def render("token.json", %{token: token}) do
    token
  end
end
