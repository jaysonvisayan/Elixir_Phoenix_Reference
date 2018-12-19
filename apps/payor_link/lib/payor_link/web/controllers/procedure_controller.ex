defmodule Innerpeace.PayorLink.Web.ProcedureController do
  use Innerpeace.PayorLink.Web, :controller
  use Innerpeace.Db.PayorRepo, :context
  alias Innerpeace.Db.Schemas.{
    Procedure,
    PayorProcedure
  }
  alias Innerpeace.Db.Base.{
    ProcedureContext,
    UserContext,
    Api.UtilityContext
  }
  # alias Innerpeace.Db.Downloader.FileDownloader

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{procedures: [:manage_procedures]},
       %{procedures: [:access_procedures]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{procedures: [:manage_procedures]},
     ]] when not action in [
       :index,
       :show
     ]

  plug :valid_uuid?, %{origin: "procedures"}
  when not action in [:index]

  def index(conn, _params) do
    pem = conn.private.guardian_default_claims["pem"]["procedures"]
    user_role =
      UserContext.get_user_role_admin(conn.assigns.current_user.id)
    is_admin =
      if Enum.empty?(user_role) == false do
        true
      else
        false
      end
    payor_procedures = ProcedureContext.get_all_procedure_query("", 0)
    render(conn, "index.html", payor_procedures: payor_procedures, is_admin: is_admin, permission: pem)
  end

  def index_load_datatable(conn, %{"params" => params}) do
    payor_procedures = ProcedureContext.get_all_procedure_query(params["search"], params["offset"])
    render(conn, Innerpeace.PayorLink.Web.ProcedureView, "load_search_procedures.json", payor_procedures: payor_procedures)
  end

  def index_load_datatable(conn, params) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
  end


  def new(conn, _params) do
    payor = get_payor_by_name!("Maxicare")
    standard_procedures = get_all_procedures()
    active_payor_procedures = get_all_payor_procedures()
    changeset = PayorProcedure.changeset(%PayorProcedure{})
    render(conn, "new.html",
           changeset: changeset,
           standard_procedures: standard_procedures,
           payor: payor,
           active_payor_procedures: active_payor_procedures)
  end

  def create_cpt(conn, %{"payor_procedure" => procedure_params}) do
    payor = get_payor_by_name!("Maxicare")
    standard_procedures = get_all_procedures()
    active_payor_procedures = get_all_payor_procedures()
    if procedure_params["exclusion_type"] == "Yes" do
      procedure_params =
        procedure_params
        |> Map.drop(["exclusion_type"])
        |> Map.merge(%{"exclusion_type" => "General Exclusion"})
    else
      procedure_params =
        procedure_params
        |> Map.drop(["exclusion_type"])
        |> Map.merge(%{"exclusion_type" => ""})
    end
    case create_payor_procedure(procedure_params) do
      {:ok, _procedure} ->
        cpt = get_procedure(procedure_params["procedure_id"])

        create_mapped_procedure_log(
          conn.assigns.current_user,
          cpt,
          procedure_params
        )

        conn
        |> put_flash(:info, "Procedure successfully added")
        |> redirect(to: procedure_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error creating procedure, please check the errors below.")
        |> render("new.html", changeset: changeset,
                  standard_procedures: standard_procedures, payor: payor,
                  active_payor_procedures: active_payor_procedures)
    end
  end

  def deactivate_cpt(conn, %{"payor_procedure" => procedure_params}) do
    payor_procedures = get_payor_procedure!(procedure_params["payor_procedure_id"])
    case deactivate_payor_procedure(procedure_params["payor_procedure_id"]) do
      {:ok, _updated_payor_procedure} ->

        create_deactivated_procedure_log(
          conn.assigns.current_user,
          payor_procedures
        )

        conn
        |> put_flash(:info, "Payor CPT successfully removed")
        |> redirect(to: procedure_path(conn, :index))
      {:error, _changeset} ->
        conn
        |> put_flash(:info, "Error deactivating procedure!")
        |> redirect(to: procedure_path(conn, :index))
    end
  end

  def edit(conn, %{"id" => id, "payor_procedure_id" => payor_procedure_id}) do
    payor = get_payor_by_name!("Maxicare")
    standard_procedures = get_all_procedures()
    procedure = get_procedure(id)
    payor_procedure =
      get_payor_procedure_by_procedure_id(id, payor_procedure_id)
    changeset = PayorProcedure.changeset(payor_procedure)
    procedure = %{cpt_code: procedure.code <> "-" <> procedure.description}
    render(conn, "edit.html", changeset: changeset,
           standard_procedures: standard_procedures, payor: payor,
           procedure: procedure, payor_procedure: payor_procedure)
  end

  def update_cpt(conn, %{"id" => id, "payor_procedure" => procedure_params}) do

    # procedure_params =
    #   procedure_params
    #   |> Map.put(
    #     "description",
    #     UtilityContext.sanitize_value(procedure_params["description"]
    #   ))

    payor = get_payor_by_name!("Maxicare")
    standard_procedures = get_all_procedures()
    payor_procedure = get_payor_procedure!(id)
    procedure = get_procedure(payor_procedure.procedure_id)
    procedure = %{cpt_code: procedure.code <> "-" <> procedure.description}
    procedure_params = validate_exclusion_params(
      procedure_params, procedure_params["exclusion_type"])

    with true <- validate_params(procedure_params),
         {:ok, _} <- update_payor_procedure(id, procedure_params)
    do
      create_updated_procedure_log(
        conn.assigns.current_user,
        PayorProcedure.changeset(payor_procedure, procedure_params)
      )

      conn
      |> put_flash(:info, "Procedure successfully updated")
      |> redirect(to: procedure_path(conn, :index))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> render("edit.html", changeset: changeset,
          standard_procedures: standard_procedures,
          payor: payor, procedure: procedure,
          payor_procedure: payor_procedure)
      _ ->
        conn
        |> put_flash(:error, "Error creating procedure.")
        |> redirect(to: procedure_path(conn, :new))
    end
  end

  defp validate_exclusion_params(params, "Yes") do
    params =
      params
      |> Map.drop(["exclusion_type"])
      |> Map.merge(%{"exclusion_type" => "General Exclusion"})
  end

  defp validate_exclusion_params(params, _) do
    params =
      params
      |> Map.drop(["exclusion_type"])
      |> Map.merge(%{"exclusion_type" => ""})
  end

  defp validate_params(params) do
    params
    |> Map.values()
    |> Enum.into([], &(validate_string(&1)))
    |> Enum.member?(true)
  end
  defp validate_params(%{}), do: true

  defp validate_string(nil), do: true
  defp validate_string(""), do: true
  defp validate_string(val), do: UtilityContext.validate_string(val)

  def get_deactivated_cpt(conn, %{"id" => procedure_id}) do
    deactivated_cpts = get_deactivated_cpts(procedure_id)
    json conn, Poison.encode!(deactivated_cpts)
  end

  def get_procedure(conn, %{"id" => id}) do
    procedure = get_procedure(id)
    render(conn, Innerpeace.PayorLink.Web.ProcedureView, "logs.json", procedure: procedure)
  end

  def get_payor_procedure(conn, %{"id" => id}) do
    payor_procedure = get_payor_procedure!(id)
    render(conn, Innerpeace.PayorLink.Web.Api.V1.ProcedureView, "procedures_index.json", procedure: payor_procedure)
  end

  def download_procedures(conn, %{"procedure_param" => download_param}) do
    data =
      [["Standard CPT Code", "Standard CPT Description", "Standard CPT Type"]] ++
      ProcedureContext.download_procedures(download_param)
     |> CSV.encode
     |> Enum.to_list
     |> to_string

    conn
    |> json(data)
  end

  def download_procedures(conn, _) do
    conn
    |> json("")
  end

  def new_import(conn, _params) do
    payor = get_payor_by_name!("Maxicare")
    standard_procedures = get_all_procedures()
    active_payor_procedures = get_all_payor_procedures()
    changeset = PayorProcedure.changeset(%PayorProcedure{})
    render(conn, "import.html",
           changeset: changeset,
           standard_procedures: standard_procedures,
           payor: payor,
           active_payor_procedures: active_payor_procedures)

  end

  def import(conn, %{"procedure" => procedure_params}) do
    case create_procedure_import(procedure_params, conn.assigns.current_user.id) do
      {:ok} ->
        conn
        |> put_flash(:info, Enum.join([procedure_params["file"].filename, " was successfully uploaded"]))
        |> redirect(to: procedure_path(conn, :new_upload_file))
      {:error, message} ->
        procedure_upload_logs = ProcedureContext.get_all_procedure_upload_logs()
        procedure_upload_file = ProcedureContext.get_procedure_upload_file()
        # active_payor_procedures = get_all_payor_procedures()
        changeset = Procedure.changeset(%Procedure{})

        conn
        |> put_flash(:error, message)
        |> render("file_uploaded.html", changeset: changeset,
                  procedure_upload_logs: procedure_upload_logs,
                  procedure_upload_file: procedure_upload_file,
                  # active_payor_procedures: active_payor_procedures
        )
    end
  end

  def download_template(conn, _params) do
    datetime_now =
      String.replace(String.replace(String.replace(DateTime.to_string(DateTime.utc_now), ".", "-"), " ", "-"), ":", "-")
    filename = Enum.join(["CPTTemplate-", datetime_now, ".csv"])
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
    |> send_resp(200, template_content())
  end

  defp template_content do
    _csv_content = [['Standard CPT Code', 'Standard CPT Description', 'Standard CPT Type'],
                    ['', '', '']]
                    |> CSV.encode
                    |> Enum.to_list
                    |> to_string
  end

  def download_uploaded_procedure_log(conn, %{"payor_procedure" => procedure_params}) do
    datetime_now =
      String.replace(String.replace(String.replace(DateTime.to_string(DateTime.utc_now), ".", "-"), " ", "-"), ":", "-")
    _filename = Enum.join(["File_-", datetime_now, ".csv"])
    procedures =
      ProcedureContext.get_procedure_upload_logs(Enum.at(procedure_params["list"], 0), Enum.at(procedure_params["list"], 1))
    csv_content = [['Remarks', 'Standard CPT Code', 'Standard CPT Description', 'Standard CPT Type']] ++ procedures
                  |> CSV.encode
                  |> Enum.to_list
                  |> to_string
    conn
    |> json(csv_content)
  end

  def new_upload_file(conn, _params) do
    procedure_upload_logs = ProcedureContext.get_all_procedure_upload_logs()
    procedure_upload_file = ProcedureContext.get_procedure_upload_file()
    # active_payor_procedures = get_all_payor_procedures()
    changeset = Procedure.changeset(%Procedure{})
    render(conn, "file_uploaded.html",
           changeset: changeset,
           procedure_upload_logs: procedure_upload_logs,
           procedure_upload_file: procedure_upload_file,
           # active_payor_procedures: active_payor_procedures
    )
  end

  def download_uploaded_file(conn, _params) do
    datetime_now =
      String.replace(String.replace(String.replace(
        DateTime.to_string(DateTime.utc_now), ".", "-"), " ", "-"), ":", "-")
    filename = Enum.join(["CPTTemplate-", datetime_now, ".csv"])
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
    |> send_resp(200, template_content())
  end

end
