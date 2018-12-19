defmodule Innerpeace.PayorLink.Web.Api.V1.Vendor.AuthorizationView do
  use Innerpeace.PayorLink.Web, :view
  alias Innerpeace.Db.Repo

  def render("authorization.json", %{authorization: auth, copy: copy, conn: conn}) do
    url =
    if Application.get_env(:payor_link, :env) == :prod do
      Atom.to_string(conn.scheme) <> "://" <> Innerpeace.PayorLink.Web.Endpoint.struct_url.host
    else
      Innerpeace.PayorLink.Web.Endpoint.url
    end

    %{
      loa_number: auth.number,
      pdf_link: "#{url}/authorizations/#{auth.id}/print_authorization?copy=#{copy}",
      status: auth.status,
      remarks: auth.internal_remarks || ""
    }
  end

end
