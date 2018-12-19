defmodule Innerpeace.PayorLink.Web.DiagnosisController do
  use Innerpeace.PayorLink.Web, :controller

  # alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Base.{
    DiagnosisContext
  }
  alias Innerpeace.Db.Schemas.{
    Diagnosis,
  }

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{diseases: [:manage_diseases]},
       %{diseases: [:access_diseases]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{diseases: [:manage_diseases]},
     ]] when not action in [
       :index,
       :show
     ]

  def index(conn, _params) do
    #diagnoses = DiagnosisContext.get_all_diagnoses()
    diagnoses = DiagnosisContext.get_all_diagnosis_query("", 0)
    render(conn, "index.html", diagnoses: diagnoses)
  end

  def index_load_datatable(conn, %{"params" => params}) do
    diagnoses = DiagnosisContext.get_all_diagnosis_query(params["search"], params["offset"])
    render(conn, Innerpeace.PayorLink.Web.DiagnosisView, "load_search_diagnosis.json", diagnoses: diagnoses)
  end

  def edit(conn, %{"id" => id}) do
    diagnosis = DiagnosisContext.get_diagnosis(id)
    changeset = Diagnosis.changeset(diagnosis)
    render(conn, "edit.html", diagnosis: diagnosis, changeset: changeset)
  end

  def update(conn, %{"id" => id, "diagnosis" => params}) do
    original_diagnosis = DiagnosisContext.get_diagnosis(id)
    with {:ok, _diagnosis} <- DiagnosisContext.update_diagnosis(id, params),
         _diagnosis_logs <- DiagnosisContext.create_update_diagnosis_log(
           conn.assigns.current_user, Diagnosis.changeset(
             original_diagnosis, params))
    do
      conn
      |> put_flash(:info, "Diagnosis updated successfully.")
      |> redirect(to: "/diseases/")
    else
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Error was encountered while saving diagnosis")
        |> render("edit.html", diagnosis: original_diagnosis, changeset: changeset)
    end
  end

  def logs(conn, %{"id" => diagnosis_id}) do
    diagnosis_logs = DiagnosisContext.get_logs(diagnosis_id)
    json conn, Poison.encode!(diagnosis_logs)
  end

  ######For CSV######

  def csv_export(conn, _params) do
    date = DateTime.to_date(DateTime.utc_now())
    year = date.year
    month = date.month
    month =
      if Enum.any?([month == 1, month == 2, month == 3, month == 4, month == 5,
      month == 6, month == 7, month == 8, month == 9]) do
        "0" <> to_string(month)
      else
        month
      end
    day = date.day
    day =
      if Enum.any?([day == 1, day == 2, day == 3, day == 4, day == 5, day == 6,
      day == 7, day == 8, day == 9]) do
        "0" <> to_string(day)
      else
        day
      end
    date = "Diagnosis_" <> to_string("#{month}-#{day}-#{year}")
      params = %{model: date}
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment;filename=\"#{params.model}.csv\"")
    |> send_resp(200, DiagnosisContext.csv_params(params.model))
  end

  # def download_diagnosis(conn, %{"diagnosis_param" => download_param}) do
  #   data = [["Primary Diagnosis Code", "Primary Diagnosis Description",
  #            "Diagnosis Group Name", "Diagnosis Chapter", "Diagnosis Type",
  #            "Congenital"]] ++ DiagnosisContext.csv_downloads(download_param)
  #            |> CSV.encode()
  #            |> Enum.to_list()
  #            |> to_string()

  #   conn
  #   |> json(data)
  # end

end
