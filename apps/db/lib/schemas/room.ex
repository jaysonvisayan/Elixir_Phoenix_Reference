defmodule Innerpeace.Db.Schemas.Room do
  @moduledoc """
  """

  use Innerpeace.Db.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Poison.Encoder, only: [
    :id,
    :code,
    :type,
    :hierarchy,
    :facility_room_rates,
    :ruv_rate
  ]}
  @timestamps_opts [usec: false]
  schema "rooms" do
    field :code, :string
    field :type, :string
    field :hierarchy, :integer
    field :ruv_rate, :string

    has_many :facility_room_rates,
      Innerpeace.Db.Schemas.FacilityRoomRate, on_delete: :nothing
    has_many :room_logs, Innerpeace.Db.Schemas.RoomLog, on_delete: :nothing

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :type,
      :hierarchy,
      :ruv_rate
    ])
    |> validate_required([
      :code,
      :type,
      :hierarchy,
      :ruv_rate
    ])
    |> unique_constraint(:code, message: "Room Code already exist!")

  end
end
