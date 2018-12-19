defmodule Innerpeace.Db.Schemas.RUVLog do
  @moduledoc """
    Schema and changesets for RUV logs
  """

  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :inserted_at,
    :message
  ]}

  schema "ruv_logs" do
    field :message, :string
    belongs_to :ruv, Innerpeace.Db.Schemas.RUV
    belongs_to :user, Innerpeace.Db.Schemas.User

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :message,
      :ruv_id,
      :user_id
    ])
    |> validate_required([
      :message,
      :ruv_id,
      :user_id
    ])
  end
end
