defmodule MemberLinkWeb.Api.V1.StatusView do
  use MemberLinkWeb, :view

  def render("index.json", %{version: version}) do
    %{
      status: "ok",
      version: version
    }
  end
end
