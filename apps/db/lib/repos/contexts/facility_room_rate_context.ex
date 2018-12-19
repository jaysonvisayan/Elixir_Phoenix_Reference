defmodule Innerpeace.Db.Base.FacilityRoomRateContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false

  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.FacilityRoomRate,
    Db.Schemas.Room
  }

  def get_all_facility_room_rate(facility_id) do
    FacilityRoomRate
    |> where([fr], fr.facility_id == ^facility_id)
    |> Repo.all
    |> Repo.preload([:room, [facility: :category]])
  end

  def get_facility_room_rate(id) do
    FacilityRoomRate
    |> Repo.get!(id)
    |> Repo.preload([:room, [facility: :category]])
   end

  def get_rooms(code) do
    Room
    |> where([r], r.code == ^code)
    |> Repo.all
  end

  def check_rooms(code) do
    rooms =
      code
      |> get_rooms()
      |> Repo.preload([facility_room_rates: [facility: [:category, :type, facility_location_groups: :location_group]]])
  end

  def delete_facility_room_rate_by_id(id) do
    FacilityRoomRate
    |> Repo.get!(id)
    |> Repo.delete
  end

  def set_facility_room_rate(attrs \\ %{}) do
    %FacilityRoomRate{}
    |> FacilityRoomRate.changeset(attrs)
    |> Repo.insert()
  end

  def update_facility_room_rate(%FacilityRoomRate{} = facility_room_rate, attrs) do
    facility_room_rate
    |> FacilityRoomRate.changeset(attrs)
    |> Repo.update()
  end

  def remove_all_facility_room_rate(facility_id) do
    FacilityRoomRate
    |> where([fr], fr.facility_id == ^facility_id)
    |> Repo.delete_all()
  end

  def changeset_facility_room_rate(%FacilityRoomRate{} = facility_room_rate) do
    FacilityRoomRate.changeset(facility_room_rate, %{})
  end

  #For Inpatient LOA
  def get_facility_room_rate_by_number(room_number) do
    FacilityRoomRate
    |> where([frr], frr.facility_room_number == ^room_number)
    |> select([frr], frr)
    |> Repo.one()
    |> Repo.preload([facility: [
      :category,
      :type,
      [facility_location_groups: :location_group]
    ]])
  end
end
