defmodule Innerpeace.PayorLink.Web.Api.V1.EmailView do
  use Innerpeace.PayorLink.Web, :view

  def render("success.json", %{message: message, code: code}) do
    %{
      message: message,
      code: code
    }
  end
end
