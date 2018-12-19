defmodule Innerpeace.PayorLink.Web.Api.V1.Vendor.ProcedureController do
  use Innerpeace.PayorLink.Web, :controller
  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.Db.Base.Api.Vendor.ProcedureContext

  def index(conn, params) do
    has_procedure = Map.has_key?(params, "procedure")
    if has_procedure do
      # Gets all records of procedure
      search_query = params["procedure"]
      payor_procedures = ProcedureContext.get_all_queried_payor_procedures(search_query)
      render(conn, Innerpeace.PayorLink.Web.Api.V1.Vendor.ProcedureView, "load_all_procedures.json", payor_procedures: payor_procedures)
    else
      conn
      |> put_status(404)
      |> render(
        Innerpeace.PayorLink.Web.Api.ErrorView,
        "error.json",
        message: "Please use procedure as parameter."
        )
    end

  end


end
