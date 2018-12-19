defmodule Innerpeace.PayorLink.Web.Api.V1.PractitionerController do
  use Innerpeace.PayorLink.Web, :controller
  # alias Innerpeace.PayorLink.Web.Api.V1.PractitionerView

  # alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Base.Api.{
    PractitionerContext,
    UtilityContext
  }
  alias PayorLink.Guardian, as: PG
  alias Innerpeace.Db.Schemas.{
    Practitioner
  }

  def index(conn, params) do
    case params do
      %{"practitioner" => nil} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Please input practitioner name")
      %{"practitioner" => practitioner_name} ->
        practitioners =
          PractitionerContext.get_all_practitioners(practitioner_name)
        render(conn, "index.json", practitioners: practitioners)
      _ ->
        practitioners = PractitionerContext.get_all_practitioners()
        render(conn, "index.json", practitioners: practitioners)
    end
  end

  def validate_affiliated_practitioner(conn, %{"params" => params}) do
    case PractitionerContext.validate_details(params) do
      {:ok,
        practitioners,
        practitioner_contact,
        practitioner_account,
        practitioner_facility,
        practitioner_specialization,
        practitioner_bank
      } ->
          practitioners =
            practitioners
            |> Map.put(:practitioner_contacts,
                practitioner_contact)
            |> Map.put(:practitioner_accounts,
                practitioner_account)
            |> Map.put(:practitioner_facilities,
                practitioner_facility)
            |> Map.put(:practitioner_specializations,
                practitioner_specialization)
            |> Map.put(:practitioner_banks,
                practitioner_bank)

          conn
          |> render(Innerpeace.PayorLink.Web.Api.V1.PractitionerView,
            "show.json", practitioners: practitioners)
      {:error, message} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: message)
    end
  end

  def validate_affiliated_practitioner(conn, params) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Invalid Parameters")
  end

  def create_practitioner_api(conn, %{"params" => params}) do
    case PractitionerContext.validate_new_practitioner(
      PG.current_resource_api(conn), params) do
      {:ok, practitioner} ->
        practitioner = PractitionerContext.get_practitioner(practitioner.id)
        conn
        |> render(Innerpeace.PayorLink.Web.Api.V1.PractitionerView,
                  "show2.json", practitioner: practitioner)
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
      {:payment_type_error, message} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: message)
    end
  end

  def get_practitioner_by_vendor_code(conn, params) do
    if params == %{} do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Vendor code is empty.")
    else
      if is_nil(params["vendor_code"]) do
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Vendor code is empty.")
      else
        vendor_code = params["vendor_code"]
        practitioner_code =
          PractitionerContext.get_practitioner_code_by_vendor_code(vendor_code)
        if practitioner_code != "" do
          render(conn, Innerpeace.PayorLink.Web.Api.V1.PractitionerView,
            "vendor_code.json", code: practitioner_code)
        else
          conn
          |> put_status(:not_found)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "There was no practitioner having the given vendor code.")
        end
      end
    end
  end

  def get_practitioner_specializations(conn, %{"id" => practitioner_id}) do
    with {true, _practitioner_id} <- UtilityContext.valid_uuid?(practitioner_id),
         %Practitioner{} <- PractitionerContext.get_practitioner(practitioner_id),
         false <- Enum.empty?(ps = get_practitioner_specializations(practitioner_id))
    do
      render(conn, "practitioner_specialization.json", practitioner_specializations: ps)
    else
      {:invalid_id} ->
        error_msg(conn, "Invalid Practitioner id.", 400)
      nil ->
        error_msg(conn, "Practitioner not found.", 404)
      _ ->
        error_msg(conn, "No Specialization found.", 404)
    end
  end

  defp get_practitioner_specializations(practitioner_id) do
    PractitionerContext.get_practitioner_specializations(practitioner_id)
  end

  def get_practitioner_by_code(conn, params) do
    if params == %{} do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Practitioner code is required.")
    else
      if is_nil(params["code"]) do
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Practitioner code is required.")
      else
        code = params["code"]
        practitioner =
          PractitionerContext.get_practitioner_by_code(code)
        if not is_nil(practitioner) do
          render(conn, Innerpeace.PayorLink.Web.Api.V1.PractitionerView,
            "practitioners3.json", practitioners: practitioner)
        else
          conn
          |> put_status(:not_found)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Practitioner not found.")
        end
      end
    end
  end

  defp error_msg(conn, message, status) do
    conn
    |> put_status(status)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: message)
  end

end
