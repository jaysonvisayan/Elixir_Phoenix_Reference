defmodule Innerpeace.Db.Schemas.PractitionerFacilityRoom do
  use Innerpeace.Db.Schema

  schema "practitioner_facility_rooms" do
    field :rate, :decimal

    belongs_to :practitioner_facility, Innerpeace.Db.Schemas.PractitionerFacility
    belongs_to :facility_room, Innerpeace.Db.Schemas.FacilityRoomRate, foreign_key: :facility_room_id

   timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params,[
      :rate,
      :practitioner_facility_id,
      :facility_room_id
    ])
    |> validate_required([
      :rate,
      :practitioner_facility_id,
      :facility_room_id
    ])
  end
end
