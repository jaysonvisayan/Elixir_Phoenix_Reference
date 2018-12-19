defmodule Innerpeace.PayorLink.Web.Api.UserView do
  use Innerpeace.PayorLink.Web, :view

  def render("login.json", %{user_id: user_id, jwt: jwt}) do
    %{
      "user_id": user_id,
      "token": jwt,
      "validated": true
    }
  end

  def render("logout.json", %{status: status}) do
      %{"message": status}
  end
end
