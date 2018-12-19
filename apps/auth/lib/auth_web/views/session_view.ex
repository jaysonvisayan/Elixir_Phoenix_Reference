defmodule AuthWeb.SessionView do
  use AuthWeb, :view

  def render("status.json", _) do
    %{
      status: "ok"
    }
  end
end
