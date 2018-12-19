defmodule RegistrationLinkWeb.PageController do
  use RegistrationLinkWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
