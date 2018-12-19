defmodule Innerpeace.PayorLink.Web.Api.FacilityController do
  use Innerpeace.PayorLink.Web, :controller
  alias Innerpeace.PayorLink.Web.FacilityView
  alias Phoenix.View
  alias Innerpeace.Db.Schemas.{
    Facility,
    FacilityRoomRate,
    FacilityPayorProcedure,
    FacilityRUV
  }

  alias Innerpeace.Db.Base.{
    FacilityContext,
    PhoneContext,
    EmailContext,
    DropdownContext,
    RoomContext,
    FacilityRoomRateContext,
    ContactContext,
    ProcedureContext,
    PractitionerContext,
    RUVContext,
    CoverageContext,
    LocationGroupContext,
    UserContext
  }

  # plug :valid_uuid?, %{origin: "facilities"}
  # when not action in [:index]
  # download facility_payor_procedure

  def download_fpp(conn, %{"id" => id, "fpp_param" => download_param}) do
    data = [["Payor Cpt Code", "Payor Cpt Name", "Provider CPT Code", "Provider CPT Name", "Room Code", "Amount", "Discount", "Effectivity Date"]] ++
      FacilityContext.fpp_csv_download(download_param, id)
      |> CSV.encode
      |> Enum.to_list
      |> to_string

    conn
    |> json(data)
  end

  def fpp_batch_download(conn, %{"log_id" => log_id, "status" => status}) do

    data = [["Payor Cpt Code", "Facility CPT Code", "Facility CPT Description", "Room Code", "Amount", "Discount", "Effective Date", "Remarks"]] ++
      FacilityContext.get_batch_log(log_id, status)
      |> CSV.encode
      |> Enum.to_list
      |> to_string

    conn
    |> json(data)

  end

  # download facility_ruv
  def download_fr(conn, %{"id" => id, "fr_param" => download_param}) do
    data = [['RUV Code', 'RUV Description',
             'RUV Type', 'Value', 'Effectivity Date'
             ]] ++
      FacilityContext.fr_csv_download(download_param, id)
      |> CSV.encode
      |> Enum.to_list
      |> to_string

    conn
    |> json(data)
  end

  def fr_batch_download(conn, %{"log_id" => log_id, "status" => status}) do

    data = [['RUV Code', 'RUV Description',
             'RUV Type', 'Value', 'Effectivity Date',
             'Remarks']] ++
      FacilityContext.get_ruv_batch_log(log_id, status)
      |> CSV.encode
      |> Enum.to_list
      |> to_string

    conn
    |> json(data)
  end
end
