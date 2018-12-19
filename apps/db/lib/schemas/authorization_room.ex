defmodule Innerpeace.Db.Schemas.AuthorizationRoom do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only:
    [
      :admission_date,
      :admission_time,
      :transfer_date,
      :transfer_time
  ]}
  schema "authorization_rooms" do
    field :admission_date, Ecto.Date
    field :admission_time, Ecto.Time
    field :transfer_date, Ecto.Date
    field :transfer_time, Ecto.Time
    field :for_isolation, :boolean

    belongs_to :authorization, Innerpeace.Db.Schemas.Authorization
    belongs_to :room, Innerpeace.Db.Schemas.Room
    belongs_to :facility_room_rate, Innerpeace.Db.Schemas.FacilityRoomRate

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :admission_date,
      :admission_time,
      :transfer_date,
      :transfer_time,
      :for_isolation,
      :authorization_id,
      :room_id,
      :facility_room_rate_id
    ])
    |> validate_required([
      :admission_date,
      :admission_time
    ])
  end

end
