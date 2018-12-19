defmodule Innerpeace.PayorLink.Web.Api.V1.DiagnosisController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Base.Api.{
    DiagnosisContext
  }
  alias Innerpeace.Db.Schemas.{
    Diagnosis
  }
  alias PayorLink.Guardian, as: PG

  def index(conn, params) do
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

  def create_diagnosis_api(conn, %{"params" => params}) do
    case DiagnosisContext.validate_insert(PG.current_resource_api(conn), params) do
      {:ok, diagnoses} ->
        render(conn, "show.json", diagnoses: diagnoses)
      {:error, changeset} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
      {:not_found} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
    end
  end

  def get_diagnosis(conn, %{"id" => id}) do
    with %Diagnosis{} = diagnosis <- DiagnosisContext.get_diagnosis(id) do
      render(conn, "show.json", diagnoses: diagnosis)
    else
      nil ->
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
    end
  end

  def get_diagnosis_by_name(conn, params) do
    diagnoses = DiagnosisContext.get_diagnosis_using_name(params["name"])
    with false <- is_nil(params["name"]),
         false <- Enum.empty?(diagnoses)
    do
      render(conn, "index.json", diagnoses: diagnoses)
    else
      _ ->
        diagnoses = DiagnosisContext.get_100_diagnosis()
        render(conn, "index.json", diagnoses: diagnoses)
    end
  end

  def get_diagnosis_by_name(conn, _params) do
    diagnoses = DiagnosisContext.get_100_diagnosis()
    render(conn, "index.json", diagnoses: diagnoses)
  end

end
