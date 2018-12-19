defmodule Innerpeace.Db.Schemas.CaseRateLog do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :inserted_at,
    :message
  ]}

  schema "case_rate_logs" do
    belongs_to :case_rate, Innerpeace.Db.Schemas.CaseRate
    belongs_to :user, Innerpeace.Db.Schemas.User
    field :message, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :case_rate_id,
      :user_id,
      :message
    ])
  end
end
