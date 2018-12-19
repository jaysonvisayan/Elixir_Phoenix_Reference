defmodule AccountLinkWeb.PageController do
  use AccountLinkWeb, :controller

  def index(conn, _params) do
    conn
    |> redirect(to: member_path(conn, :index, conn.assigns.locale))
  end
end
