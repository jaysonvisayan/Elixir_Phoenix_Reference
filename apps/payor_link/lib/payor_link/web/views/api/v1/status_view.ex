defmodule Innerpeace.PayorLink.Web.Api.V1.StatusView do
  use Innerpeace.PayorLink.Web, :view

  def render("index.json", %{version: version}) do
    %{
      status: "ok",
      version: version
    }
  end

  def render("success.json", %{}) do
    %{
        success: true
    }
  end
end
