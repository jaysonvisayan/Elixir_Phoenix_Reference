defmodule Innerpeace.Db.Schemas.RoomLog do
  @moduledoc false

  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :inserted_at,
    :message
  ]}
  schema "room_logs" do
    belongs_to :room, Innerpeace.Db.Schemas.Room
    belongs_to :user, Innerpeace.Db.Schemas.User
    field :message, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :room_id,
      :user_id,
      :message
    ])
    |> validate_required([
      :user_id,
      :message
    ])
  end

end
