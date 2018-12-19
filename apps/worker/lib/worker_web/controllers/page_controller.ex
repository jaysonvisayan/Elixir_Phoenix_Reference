defmodule WorkerWeb.PageController do
  use WorkerWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
