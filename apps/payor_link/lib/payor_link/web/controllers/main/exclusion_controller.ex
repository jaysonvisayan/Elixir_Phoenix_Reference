defmodule Innerpeace.PayorLink.Web.Main.ExclusionController do
  use Innerpeace.PayorLink.Web, :controller
  use Innerpeace.Db.PayorRepo, :context

  alias Innerpeace.Db.Base.{
    ExclusionContext,
    BenefitContext,
    CoverageContext,
    DiagnosisContext,
    ProcedureContext,
    PackageContext,
    UserContext,
  }

  plug :valid_uuid?, %{origin: "web/exclusions"}
  when not action in [:index]

  alias Innerpeace.Db.{
    Schemas.Diagnosis,
    Datatables.ExclusionDiseaseDatatable,
    Datatables.ExclusionCondition
  }

  def index(conn, _) do
    render(conn, "index.html")
  end

  def view(conn, %{"code" => code}) do
    render(conn, "view.html", code: code)
  end

  def view_general(conn, %{"code" => code}) do
    render(conn, "view_general.html", code: code)
  end

  def show(conn, %{"id" => nil}) do
    conn
    |> put_flash(:info, "Page does not exist.")
    |> redirect(to: main_exclusion_path(conn, :index))
  end

  def show(conn, %{"id" => id}) do
    pem = conn.private.guardian_default_claims["pem"]["exclusions"]
    exclusion = ExclusionContext.get_exclusion(id)
    coverage = exclusion.coverage
    user = UserContext.get_user(exclusion.updated_by_id)
    render(conn, "show.html", exclusion: exclusion, coverage: coverage, user: user, tab_checker: "exclusion_procedure", permission: pem)
  end

  def load_diagnosis(conn, params) do
    exclusion_id = params["id"]
    ExclusionDiseaseDatatable.initialize_query(exclusion_id)
    data = ExclusionDiseaseDatatable.insert_diagnosis_exclusion(params["start"], params["length"], params["search"]["value"], params["order"]["0"], exclusion_id)
    count = ExclusionDiseaseDatatable.disease_count(exclusion_id)
    filtered_count = ExclusionDiseaseDatatable.get_disease_filtered_count(params["search"]["value"], exclusion_id)

    conn
    |> json(%{
      data: data,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  def load_condition(conn, params) do
    exclusion_id = params["id"]
    ExclusionCondition.initialize_query(exclusion_id)
    data = ExclusionCondition.insert_exclusion_condition(params["start"], params["length"], params["search"]["value"], params["order"]["0"], exclusion_id)
    count = ExclusionCondition.count(exclusion_id)
    filtered_count = ExclusionCondition.get_filtered_count(params["search"]["value"], exclusion_id)

    conn
    |> json(%{
      data: data,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

end
