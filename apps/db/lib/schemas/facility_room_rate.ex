defmodule Innerpeace.Db.Schemas.FacilityRoomRate do
  use Innerpeace.Db.Schema

  @timestamps_opts [usec: false]
  @derive {Poison.Encoder, only: [:facility, :facility_room_type, :facility_room_rate, :id, :facility_ruv_rate]}
  schema "facility_room_rates" do
    belongs_to :facility, Innerpeace.Db.Schemas.Facility
    belongs_to :room, Innerpeace.Db.Schemas.Room
    field :facility_room_type, :string
    field :facility_room_rate, :string
    field :facility_ruv_rate, :decimal
    field :facility_room_number, :string

    has_many :practitioner_facility_rooms, Innerpeace.Db.Schemas.PractitionerFacilityRoom
    many_to_many :practitioner_facilities, Innerpeace.Db.Schemas.PractitionerFacility, join_through: "practitioner_facility_rooms"
    has_many :facility_payor_procedure_rooms, Innerpeace.Db.Schemas.FacilityPayorProcedureRoom, on_delete: :delete_all

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:facility_id, :room_id, :facility_room_type, :facility_room_rate, :facility_ruv_rate, :facility_room_number])
    |> validate_required([:facility_id, :room_id])
  end
end
