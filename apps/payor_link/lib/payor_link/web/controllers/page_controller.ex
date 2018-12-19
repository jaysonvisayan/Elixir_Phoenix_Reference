defmodule Innerpeace.PayorLink.Web.PageController do
  use Innerpeace.PayorLink.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def sample_forms(conn, _params) do
    render conn, "forms.html"
  end

  def sample_print(conn, _params) do
    render conn, "print.html"
  end
end
