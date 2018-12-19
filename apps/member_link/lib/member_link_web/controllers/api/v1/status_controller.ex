defmodule MemberLinkWeb.Api.V1.StatusController do
  use MemberLinkWeb, :controller

  def index(conn, _params) do
    version = Application.spec(:member_link, :vsn)
    version = version
              |> String.Chars.to_string
    render(conn, "index.json", %{version: version})
  end
end
