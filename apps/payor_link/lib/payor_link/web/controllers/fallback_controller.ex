defmodule Innerpeace.PayorLink.Web.FallbackController do
  use Innerpeace.PayorLink.Web, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> render(Innerpeace.PayorLink.Web.ErrorView, :"404")
  end

  def call(conn, nil) do
    conn
    |> render(Innerpeace.PayorLink.Web.ErrorView, :"404")
  end

  def call(conn, {:error, :unauthenticated}) do
    conn
    |> put_status(:unauthenticated)
    |> put_flash(:error, "Unauthenticated")
    |> render(Innerpeace.PayorLink.Web.ErrorView, :"401")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_flash(:error, "Unauthorized")
    |> render(Innerpeace.PayorLink.Web.ErrorView, :"401")
  end

  def call(conn, {:error, :no_resource_found}) do
    conn
    |> put_flash(:error, "You are not authorized to access this page")
    |> redirect(to: "/")
  end

  defp logout(conn) do
    conn
    |> PayorLink.Guardian.Plug.sign_out
    |> Plug.Conn.configure_session(drop: true)
  end
end
