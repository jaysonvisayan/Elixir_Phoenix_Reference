defmodule Innerpeace.PayorLink.Web.Api.V1.ProcedureController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Base.Api.ProcedureContext
  alias Innerpeace.Db.{
    Repo,
    Schemas.Procedure,
    Schemas.PayorProcedure
  }
  def load_procedures(conn, params) do
    # Gets all records of procedure

    search_query = params["procedure"]

    payor_procedures = ProcedureContext.get_all_queried_payor_procedures(search_query)
    render(conn, Innerpeace.PayorLink.Web.Api.V1.ProcedureView, "load_all_procedures.json", payor_procedures: payor_procedures)
  end

  def create(conn, params) do
    case ProcedureContext.create(params) do
      {:ok, payor_procedure} ->
        conn
        |> render("payor_procedure.json", payor_procedure: payor_procedure)
      {:error, message} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: message)
    end
  end

  def get_procedure(conn, %{"id" => id}) do
    with %Procedure{} = procedure <- ProcedureContext.get_procedure(id) do
      render(conn, "procedure.json", procedure: procedure)
    else
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
    end
  end

  def get_payor_procedure(conn, %{"id" => id}) do
    with %PayorProcedure{} = payor_procedure <- ProcedureContext.get_payor_procedure(id) do
      payor_procedure = payor_procedure |> Repo.preload([:procedure])
      render(conn, "payor_procedure.json", payor_procedure: payor_procedure)
    else
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
    end
  end

end
