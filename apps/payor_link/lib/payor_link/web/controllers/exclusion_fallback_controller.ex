defmodule Innerpeace.PayorLink.Web.ExclusionFallbackController do
  use Innerpeace.PayorLink.Web, :controller

  def call(conn, nil) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Pre Existing not found.")
  end

  def call(conn, message) do
    conn
    |> put_status(500)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: message)
  end

  def call(conn, {:error, :unauthenticated}) do
    conn
    |> put_status(:unauthenticated)
    |> put_flash(:error, "Unauthenticated")
    |> render(Innerpeace.PayorLink.Web.ErrorView, :"401")
  end

  def call(conn, _) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid Parameters")
  end

end
