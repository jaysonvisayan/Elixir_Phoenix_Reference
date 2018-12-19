defmodule Innerpeace.PayorLink.Web.Main.PageController do
  use Innerpeace.PayorLink.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
