defmodule Innerpeace.Db.Schemas.FacilityPayorProcedureRoom do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :amount,
    :discount,
    :start_date,
    :id,
    :facility_room_rate
  ]}

  schema "facility_payor_procedure_rooms" do
    field :amount, :decimal
    field :discount, :decimal
    field :start_date, Ecto.Date

    belongs_to :facility_payor_procedure, Innerpeace.Db.Schemas.FacilityPayorProcedure
    belongs_to :facility_room_rate, Innerpeace.Db.Schemas.FacilityRoomRate

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :amount,
      :discount,
      :start_date,
      :facility_payor_procedure_id,
      :facility_room_rate_id
    ])
    |> validate_required([
      :amount,
      :discount,
      :start_date,
      :facility_payor_procedure_id,
      :facility_room_rate_id
    ])
  end
end
