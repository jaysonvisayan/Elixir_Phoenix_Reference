defmodule Innerpeace.Db.Schemas.DiagnosisLog do
  @moduledoc """
    Schema and changesets for Diagnosis logs
  """

  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :inserted_at,
    :message
  ]}

  schema "diagnosis_logs" do
    field :message, :string
    belongs_to :diagnosis, Innerpeace.Db.Schemas.Diagnosis
    belongs_to :user, Innerpeace.Db.Schemas.User

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :message,
      :diagnosis_id,
      :user_id
    ])
    |> validate_required([
      :message,
      :diagnosis_id,
      :user_id
    ])
  end
end
