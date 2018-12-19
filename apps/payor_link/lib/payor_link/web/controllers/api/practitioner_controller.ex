defmodule Innerpeace.PayorLink.Web.Api.PractitionerController do
  use Innerpeace.PayorLink.Web, :controller
  alias Innerpeace.PayorLink.Web.PractitionerView
  alias Innerpeace.Db.Base.{
    PractitionerContext
  }

  # Start of Practitioner Download Results

  def download_practitioner(conn, %{"practitioner_param" => download_param}) do
    data = PractitionerContext.practitioner_csv_downloads(download_param)
    # conn
    json conn, Poison.encode!(data)
  end
end
