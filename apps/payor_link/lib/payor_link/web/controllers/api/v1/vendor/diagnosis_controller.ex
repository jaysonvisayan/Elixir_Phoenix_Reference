defmodule Innerpeace.PayorLink.Web.Api.V1.Vendor.DiagnosisController do
  use Innerpeace.PayorLink.Web, :controller
  import Ecto.{Query, Changeset}, warn: false

  alias Innerpeace.Db.Base.Api.{
    Vendor.DiagnosisContext
  }

  @moduledoc false

  def index(conn, params) do
    #raise params
    has_diagnosis = Map.has_key?(params, "diagnosis")
    if Enum.count(params) >= 1 do
      if has_diagnosis and is_nil(params["diagnosis"]) do
        conn
        |> put_status(404)
        |> render(
          Innerpeace.PayorLink.Web.Api.ErrorView,
          "error.json",
          message: "Please input diagnosis description or code."
        )
      else
        params =
          params
          |> Map.put_new("diagnosis", "")
          diagnoses = DiagnosisContext.search_diagnosis(params)
          render(conn, "index.json", diagnoses: diagnoses)
      end
    else
      diagnoses = DiagnosisContext.search_all_diagnosis()
      render(conn, "index.json", diagnoses: diagnoses)
    end
  end


end
