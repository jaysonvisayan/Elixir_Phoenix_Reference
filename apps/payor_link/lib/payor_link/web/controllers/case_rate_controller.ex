defmodule Innerpeace.PayorLink.Web.CaseRateController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Base.{
    CaseRateContext,
    DiagnosisContext,
    RUVContext
  }
  alias Innerpeace.Db.Schemas.{
    CaseRate
    # Diagnosis,
    # RUV
  }

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{caserates: [:manage_caserates]},
       %{caserates: [:access_caserates]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{caserates: [:manage_caserates]},
     ]] when not action in [
       :index,
       :show
     ]

  plug :valid_uuid?, %{origin: "case_rates"}
  when not action in [:index]

  def index(conn, _params) do
    pem = conn.private.guardian_default_claims["pem"]["caserates"]
    case_rates = CaseRateContext.get_all_case_rate()
    render(conn, "index.html", case_rates: case_rates, permission: pem)
  end

  def new(conn, _params) do
    changeset = CaseRate.changeset(%CaseRate{})
    diagnoses = DiagnosisContext.get_all_diagnoses()
    case_rates = CaseRateContext.get_all_case_rate()
    ruvs = RUVContext.get_ruvs()
    render(conn, "new.html", changeset: changeset, diagnoses: diagnoses, case_rates: case_rates, ruvs: ruvs)
  end

  def create(conn, %{"case_rate" => case_rate_params}) do
    if case_rate_params["hierarchy1"] == "on" do
      case_rate_params =
        case_rate_params
        |> Map.put("hierarchy1", "1")
        |> Map.put("discount_percentage1", "100")
    else
      case_rate_params =
        case_rate_params
        |> Map.delete("hierarchy1")
    end

    if case_rate_params["hierarchy2"] == "on" do
      case_rate_params =
        case_rate_params
        |> Map.put("hierarchy2", "2")
        |> Map.put("discount_percentage2", "50")
    else
      case_rate_params =
        case_rate_params
        |> Map.delete("hierarchy2")
    end

    case_rate_params =
      case_rate_params
      |> Map.put("created_by_id", conn.assigns.current_user.id)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

    if case_rate_params["type"] == "ICD" do
      case_rate_params = Map.delete(case_rate_params, "ruv_id")
    else
      case_rate_params = Map.delete(case_rate_params, "diagnosis_id")
    end

    case CaseRateContext.create_case_rate(case_rate_params) do
      {:ok, case_rate} ->
        create_case_rate_log(conn, case_rate)

        conn
        |> put_flash(:info, "Case Rate created successfully.")
        |> redirect(to: case_rate_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:info, "Error was encountered while saving case_rate")
        |> render(conn, "new.html", changeset: changeset)
    end
  end

  defp create_case_rate_log(conn, case_rate) do
    if is_nil(case_rate.diagnosis_id) do
      ruv = RUVContext.get_ruv_by_id(case_rate.ruv_id)
      params = %{
        case_rate_code: ruv.code,
        case_rate_type: case_rate.type,
        description: case_rate.description,
        amount_up_to: case_rate.amount_up_to,
        first_hierarchy: case_rate.hierarchy1 || 0,
        second_hierarchy: case_rate.hierarchy2 || 0,
        discount_percentage_of_first_hierarchy: case_rate.discount_percentage1 || 0,
        discount_percentage_of_second_hierarchy: case_rate.discount_percentage2 || 0
      }

    else
      diagnosis = DiagnosisContext.get_diagnosis(case_rate.diagnosis_id)
      params = %{
          case_rate_code: diagnosis.code,
          case_rate_type: case_rate.type,
          description: case_rate.description,
          amount_up_to: case_rate.amount_up_to,
          first_hierarchy: case_rate.hierarchy1 || 0,
          second_hierarchy: case_rate.hierarchy2 || 0,
          discount_percentage_of_first_hierarchy: case_rate.discount_percentage1 || 0,
          discount_percentage_of_second_hierarchy: case_rate.discount_percentage2 || 0
         }
    end

     CaseRateContext.create_case_rate_logs(
      case_rate,
      conn.assigns.current_user,
      params
    )
  end

  def show(conn, %{"id" => id}) do
    case_rates = CaseRateContext.get_case_rate(id)
    render(conn, "show.html", case_rates: case_rates)
  end

  def edit(conn, %{"id" => id}) do
    case_rates = CaseRateContext.get_case_rate(id)
    case_rates_list = CaseRateContext.get_all_case_rate()
    changeset = CaseRate.changeset(case_rates)
    diagnoses = DiagnosisContext.get_all_diagnoses()
    render(conn, "edit.html",
      case_rates: case_rates,
      changeset: changeset,
      diagnoses: diagnoses,
      case_rates_list: case_rates_list
    )
  end

  def update(conn, %{"id" => id, "case_rate" => case_rate_params}) do
    case_rates = CaseRateContext.get_case_rate(id)

    if case_rate_params["hierarchy1"] == "on" do
      case_rate_params =
        case_rate_params
        |> Map.put("hierarchy1", "1")
        |> Map.put("discount_percentage1", "100")
    else
      case_rate_params =
        case_rate_params
        |> Map.put("hierarchy1", nil)
        |> Map.put("discount_percentage1", nil)
    end

    if case_rate_params["hierarchy2"] == "on" do
      case_rate_params =
        case_rate_params
        |> Map.put("hierarchy2", "2")
        |> Map.put("discount_percentage2", "50")
    else
      case_rate_params =
        case_rate_params
        |> Map.put("hierarchy2", nil)
        |> Map.put("discount_percentage2", nil)
    end

    case CaseRateContext.update_case_rate(id, case_rate_params) do
      {:ok, _case_ratesee} ->

        CaseRateContext.create_case_rate_edit_logs(
          conn.assigns.current_user,
          CaseRate.changeset(case_rates, case_rate_params)
        )
        conn
        |> put_flash(:info, "Case Rate updated successfully.")
        |> redirect(to: case_rate_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:info, "Error was encountered while saving case_rate")
        |> render(conn, "edit.html", case_rates: case_rates, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    _case_rate = CaseRateContext.delete_case_rate(id)

    conn
    |> put_flash(:info, "Case Rate deleted successfully.")
    |> redirect(to: case_rate_path(conn, :index))
  end

  def show_logs(conn, %{"id" => id}) do
    case_rate_logs = CaseRateContext.get_all_case_rate_logs(id)
    # json conn, Poison.encode!(case_rate_logs)
    conn
    |> render(
      Innerpeace.PayorLink.Web.CaseRateView,
      "case_rate_logs.json",
      case_rate_logs: case_rate_logs
    ) 
  end

  def search_logs(conn, %{"id" => id, "message" => message}) do
    case_rate_logs = CaseRateContext.get_case_rate_logs(id, message)
    json conn, Poison.encode!(case_rate_logs)
  end
end
