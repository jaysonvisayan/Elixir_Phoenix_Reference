defmodule Innerpeace.PayorLink.Web.Api.DiagnosisController do
  use Innerpeace.PayorLink.Web, :controller

  # alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Base.{
    DiagnosisContext,
    UtilityContext
  }

  def download_diagnosis(conn, %{"diagnosis_param" => download_param}) do
    with true <- UtilityContext.is_valid_string?(download_param["search_value"]) do
      data = [["Primary Diagnosis Code", "Primary Diagnosis Description",
               "Diagnosis Group Name", "Diagnosis Chapter", "Diagnosis Type",
               "Congenital"]] ++ DiagnosisContext.csv_downloads(UtilityContext.sanitize_param(download_param))
               |> CSV.encode()
               |> Enum.to_list()
               |> to_string()

               conn
               |> json(data)
    else
      false ->
        json conn, Poison.encode!(%{valid: false})
    end
  end

  def download_diagnosis(conn, params) do
    conn
    |> put_status(404)
    |> json("")
  end

end
