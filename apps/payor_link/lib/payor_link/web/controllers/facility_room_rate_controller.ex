defmodule Innerpeace.PayorLink.Web.FacilityRoomRateController do
  use Innerpeace.PayorLink.Web, :controller
  # use Innerpeace.Db.PayorRepo, :context

  # alias Innerpeace.Db.Repo
  # alias Innerpeace.Db.Schemas.{
    # Room,
    # Facility,
    # FacilityRoomRate
  # }
  alias Innerpeace.Db.Base.{
    FacilityContext,
    BenefitContext,
    FacilityRoomRateContext
  }

  def create_room_rate(conn, %{"id" => facility_id, "facility_room_rate" => facility_room_rate_params}) do
    facility_room_rate_params =
      facility_room_rate_params
      |> Map.merge(%{"facility_id" => facility_id})
    case FacilityRoomRateContext.set_facility_room_rate(facility_room_rate_params) do
      {:ok, _facility_room_rate} ->
      conn
        |> put_flash(:info, "Rooms Added Successfully")
        |> redirect(to: "/facilities/#{facility_id}?active=room")
      {:error, %Ecto.Changeset{} = _changeset} ->
        conn
        |> put_flash(:error, "Error Transaction not Successfull")
        |> redirect(to: "/facilities/#{facility_id}?active=room")
    end

  end

  def update_room_rate(conn, %{"id" => facility_id, "facility_room_rate" => facility_room_rate_params}) do
    facility_room_rate_params =
      facility_room_rate_params
      |> Map.merge(%{"facility_id" => facility_id})
    facility_room_rate = FacilityRoomRateContext.get_facility_room_rate(facility_room_rate_params["room_rate_id"])
    ruv_rate = Decimal.new(String.replace(facility_room_rate_params["facility_ruv_rate"], ",", ""))
    facility_room_rate_params = Map.put(facility_room_rate_params, "facility_ruv_rate", ruv_rate)
    case FacilityRoomRateContext.update_facility_room_rate(facility_room_rate, facility_room_rate_params) do
      {:ok, _facility_room_rate} ->
        conn
        |> put_flash(:info, "Rooms Updated Successfully")
        |> redirect(to: "/facilities/#{facility_id}?active=room")
      {:error, %Ecto.Changeset{} = _changeset} ->
        conn
        |> put_flash(:error, "Error Transaction not Successfull")
        |> redirect(to: "/facilities/#{facility_id}?active=room")
    end

  end

  def delete_room_rate(conn, %{"room_rate_id" => room_rate_id, "id" => facility_id}) do
    {:ok, _facility_room_rate} = FacilityRoomRateContext.delete_facility_room_rate_by_id(room_rate_id)
    fpps = FacilityContext.get_all_facility_payor_procedures(facility_id)
    for fpp <- fpps do
      if fpp.facility_payor_procedure_rooms == [] do
        FacilityContext.delete_facility_payor_procedure(fpp.id)
      end
    end
    conn
    |> put_flash(:info, "Room Successfully Remove")
    |> redirect(to: "/facilities/#{facility_id}?active=room")
  end

  def get_rooms_using_code(conn, %{"code" => code}) do
    hierarchy = FacilityRoomRateContext.check_rooms(code)
    json conn, Poison.encode!(hierarchy)
  end

end
