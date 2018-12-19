defmodule Innerpeace.PayorLink.Web.LayoutView do
  use Innerpeace.PayorLink.Web, :view
  alias PayorLink.Guardian.Plug

  def version do
    Application.spec(:payor_link, :vsn)
  end

  def image_url_for(uploader, path, resource, version \\ :original) do
    sanitize_url uploader.url({path, resource}, version)
  end

  defp sanitize_url("apps/payor_link/assets/static" <> url), do: url
  defp sanitize_url(url), do: url  |> String.replace("/apps/payor_link/assets/static", "")

  def file_url_for(uploader, path, resource) do
    sanitize_url uploader.url({path, resource}, version)
  end

  def valid_timezone(date) do
    {:ok, datetime} = DateTime.from_naive(date, "Etc/UTC")
    datetime
  end

  def generate_api_token(conn) do
    secure_random = Plug.current_resource(conn)
    new_conn = Plug.sign_in(conn, secure_random)
    jwt = Plug.current_token(new_conn)
  end
end
