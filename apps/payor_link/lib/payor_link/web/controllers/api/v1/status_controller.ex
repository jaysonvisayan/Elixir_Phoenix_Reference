defmodule Innerpeace.PayorLink.Web.Api.V1.StatusController do
  use Innerpeace.PayorLink.Web, :controller

  def index(conn, _params) do
    version = :payor_link |> Application.spec(:vsn) |> String.Chars.to_string
    render(conn, "index.json", %{version: version})
  end
end
